DO
$$
    DECLARE
        rec_boletos              RECORD;
        rec_modificadores        RECORD;
        var_acrescimos           NUMERIC(10, 2) := 0;
        var_descontos            NUMERIC(10, 2) := 0;
        var_valorcredito         NUMERIC(10, 2) := 0;
        var_data_melhor_desconto DATE;
        var_sql                  VARCHAR;
    BEGIN

        FOR rec_boletos IN
            SELECT car.boletos.codigo,
                   car.boletos.motivo,
                   car.boletos.valorboleto,
                   car.boletos.datavencto,
                   CURRENT_DATE AS datacalculo,
                   --CASE WHEN car.boletos.datavencto < NOW()::DATE
                   -- THEN car.boletos.datavencto ELSE NOW()::DATE END AS datacalculo,
                   (
                       SELECT codigo
                       FROM car.boletosanalises
                       WHERE datafim IS NULL
                         AND boleto = car.boletos.codigo
                   )            AS codigo_analise,
                   (
                       SELECT TRUE
                       FROM car.modificadoresgerados,
                            car.modificadores
                       WHERE car.modificadoresgerados.boleto = car.boletos.codigo
                         AND car.modificadoresgerados.modificador = car.modificadores.codigo
                         AND car.modificadores.categoria IN (1000, 1075, 1079)
                       LIMIT 1
                   )            AS possui_fies
            FROM car.boletos
            WHERE car.boletos.status = 5
              --AND car.boletos.datavencto > '31/12/2005'::DATE
              AND (EXTRACT(YEAR FROM CURRENT_DATE)::VARCHAR || LPAD(EXTRACT(MONTH FROM CURRENT_DATE)::VARCHAR, 2, '0'))
                >= (EXTRACT(YEAR FROM car.boletos.datavencto)::VARCHAR || LPAD(EXTRACT(MONTH FROM car.boletos.datavencto)::VARCHAR, 2, '0'))
        LOOP

            -- inicializando acumuladores
            var_acrescimos := 0;
            var_descontos := 0;

            -- Recalculando a melhor data de desconto para boletos que tiverem seus descontos lançados depois da melhor data
            IF TO_CHAR(rec_boletos.datavencto, '01/MM/YYYY')::DATE = CURRENT_DATE OR rec_boletos.possui_fies THEN
                IF rec_boletos.datacalculo > rec_boletos.datavencto THEN
                    rec_boletos.datacalculo := rec_boletos.datavencto;
                END IF;
                SELECT MIN(datafim)
                FROM car.modificadoresporboleto
                WHERE boleto = rec_boletos.codigo
                INTO var_data_melhor_desconto;
                IF var_data_melhor_desconto IS NOT NULL THEN
                    rec_boletos.datacalculo := var_data_melhor_desconto;
                END IF;
            END IF;

            -- Somo todos os descontos e acréscimos dos modificadores gerados do boleto
            FOR rec_modificadores IN
                SELECT car.modificadoresgerados.valor,
                       car.tiposmodificadores.fluxo,
                       car.categoriasmodificadores.validoatevencto
                FROM car.modificadoresgerados
                JOIN car.modificadores ON car.modificadores.codigo = car.modificadoresgerados.modificador
                JOIN car.categoriasmodificadores ON car.categoriasmodificadores.codigo = car.modificadores.categoria
                JOIN car.tiposmodificadores ON car.tiposmodificadores.codigo = car.categoriasmodificadores.tipo
                WHERE car.modificadoresgerados.boleto = rec_boletos.codigo
                  AND car.modificadoresgerados.tipovalor = 1
            LOOP
                IF rec_modificadores.validoatevencto AND rec_boletos.datacalculo > rec_boletos.datavencto THEN
                    CONTINUE;
                END IF;
                IF rec_modificadores.fluxo = 1 THEN
                    var_acrescimos := var_acrescimos + rec_modificadores.valor;
                    CONTINUE;
                END IF;
                var_descontos := var_descontos + rec_modificadores.valor;
            END LOOP;

            -- Somo todos os descontos e acréscimos dos modificadores por boleto do boleto
            FOR rec_modificadores IN
                SELECT valor, fluxo
                FROM car.modificadoresporboleto
                WHERE boleto = rec_boletos.codigo
                  AND rec_boletos.datacalculo BETWEEN datainicio AND datafim
                  AND tipovalor = 1
            LOOP
                IF rec_modificadores.fluxo = 1 THEN
                    var_acrescimos := var_acrescimos + rec_modificadores.valor;
                    CONTINUE;
                END IF;
                var_descontos := var_descontos + (rec_modificadores.valor * -1);
            END LOOP;

            --Validação para baixa de crédito 100%
            SELECT SUM(car.modificadoresgerados.valor)
            FROM car.modificadoresgerados
            JOIN car.modificadores ON car.modificadores.codigo = car.modificadoresgerados.modificador
            JOIN car.categoriasmodificadores ON car.categoriasmodificadores.codigo = car.modificadores.categoria
            JOIN car.tiposmodificadores ON car.tiposmodificadores.codigo = car.categoriasmodificadores.tipo
            WHERE car.modificadoresgerados.boleto = rec_boletos.codigo
              AND car.modificadoresgerados.tipovalor = 1 --Dinheiro
              AND car.tiposmodificadores.fluxo = 2       --Desconto
              AND car.modificadores.codigo = 5542        --Desconto por crédito 'X DESCREDITO'
            INTO var_valorcredito;

            IF rec_boletos.valorboleto + var_acrescimos - var_descontos != 0 THEN
                CONTINUE ;
            END IF;

            IF var_valorcredito > 0
                AND var_valorcredito = var_descontos
                AND rec_boletos.valorboleto + var_acrescimos - var_descontos = 0
                AND rec_boletos.motivo <> 4
            THEN
                CONTINUE ;
            END IF;

            IF car.sp_boleto_negociacao_pendente(rec_boletos.codigo) = TRUE THEN
                CONTINUE;
            END IF;

            RAISE NOTICE '--> BAIXA 100: %', rec_boletos.codigo;

            -- Atualizo os modificadores gerados
            --var_sql := 'UPDATE car.modificadoresgerados SET utilizado = TRUE WHERE boleto = '||rec_boletos.codigo||';';
            --UPDATE temp_tbl SET tipo = 'A', tabela = 'car.modificadoresgerados', sql = var_sql, operacao = op_carmodificadoresgerados_a;
            --EXECUTE var_sql;

            -- Atualizo os modificadores por boleto
            --var_sql := 'UPDATE car.modificadoresporboleto SET utilizado = TRUE WHERE tipovalor = 1 AND '''||rec_boletos.datacalculo||'''::DATE BETWEEN datainicio AND datafim AND boleto = '||rec_boletos.codigo||';';
            --UPDATE temp_tbl SET tipo = 'A', tabela = 'car.modificadoresporboleto', sql = var_sql, operacao = op_carmodificadoresporboleto_a;
            --EXECUTE var_sql;

            -- Atualizo os valores e efetuo a baixa no boleto
            --var_sql := 'UPDATE car.boletos SET status = 6, datapagamento = '''||rec_boletos.datacalculo||''', databaixa = NOW(), valorliquido = 0, valordiferenca = 0, pago = TRUE, localpagamento = 1, valorjuros = 0, valormulta = 0, valordescontos = '||var_descontos||', valoracrescimos = '||var_acrescimos||', observacoesinternas = ''Boleto baixado automaticamente em processo de baixa de boletos 100%.'' WHERE codigo = '||rec_boletos.codigo||';';
            --UPDATE temp_tbl SET tipo = 'A', tabela = 'car.boletos', sql = var_sql, operacao = op_carboletos_a;
            --EXECUTE var_sql;

            -- Finalizando a Análise do Boleto
            IF rec_boletos.codigo_analise IS NOT NULL THEN
                --var_sql := 'UPDATE car.boletosanalises SET datafim = NOW(), observacaointerna = ''Análise concluída automaticamente em processo de baixa de boletos 100%.'' WHERE codigo = '||rec_boletos.codigo_analise||';';
                --UPDATE temp_tbl SET tipo = 'A', tabela = 'car.boletosanalises', sql = var_sql, operacao = op_carboletosanalises_a;
                --EXECUTE var_sql;
            END IF;

        END LOOP;
    END
$$;
