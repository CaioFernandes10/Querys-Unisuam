CREATE OR REPLACE FUNCTION gra.sp_periodoletivo_conclusao_previsao_nova_regra(par_aluno INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE plpgsql
AS
$$
/*******************************************************************************
NOME: gra.sp_periodoletivo_conclusao_previsao
--------------------------------------------------------------------------------
DESCRIÇÃO: Retorna previsão do periodo letivo de conclusão
--------------------------------------------------------------------------------
PARAMETROS:
  par_aluno (INT, NOT NULL) => Código do Aluno (gra.alunos.codigo)
--------------------------------------------------------------------------------
SAIDA: Período Letivo (gra.periodosletivos.label)
--------------------------------------------------------------------------------
DEPENDENCIAS:
--------------------------------------------------------------------------------
UTILIZADA EM:
--------------------------------------------------------------------------------
CRIAÇÃO: 21/11/2018 - Roger Ferreira
         08/11/2022 - João R Almeida
*******************************************************************************/
DECLARE
    var_periodo_letivo_atual        VARCHAR;
    int_histotico                   INTEGER;
    rec_aluno                       RECORD;
    int_creditos_acursar            INTEGER := 0;
    int_creditos_emcurso            INTEGER := 0;
    int_semestres_incrementar       INTEGER := 0;
    int_periodos_cursados           INTEGER := 0;
    int_minimo_semestre_incrementar INTEGER := 0;
BEGIN

    SELECT gra.sp_periodoletivo_atual() INTO var_periodo_letivo_atual;
    SELECT gra.sp_historico_atual(par_aluno) INTO int_histotico;

    SELECT gra.periodosletivos.label  AS periodoletivo_conclusao,
           gra.alunos.formadeingresso AS formaingresso_id,
           gra.estruturas.formato     AS formato_id,
           gra.estruturas.minperiodosconclusao,
           gra.estruturas.maxcrperiodo
    FROM gra.historicos
    JOIN gra.inscricoes ON gra.inscricoes.codigo = gra.historicos.inscricao
    JOIN gra.alunos ON gra.alunos.codigo = gra.inscricoes.aluno
    JOIN gra.estruturas ON gra.estruturas.codigo = gra.historicos.estrutura
    LEFT JOIN gra.periodosletivos ON gra.periodosletivos.codigo = gra.inscricoes.periodoletivoconclusao
    WHERE gra.historicos.codigo = int_histotico
    INTO rec_aluno;

    --RAISE NOTICE 'int_histotico: %', int_histotico;
    --RAISE NOTICE 'rec_aluno.formaingresso_id: %', rec_aluno.formaingresso_id;
    --RAISE NOTICE 'rec_aluno.minperiodosconclusao: %', rec_aluno.minperiodosconclusao;
    --RAISE NOTICE 'rec_aluno.maxcrperiodo: %', rec_aluno.maxcrperiodo;

    -- -----------------------------------------------------------------------------------------------------------------
    -- FORMATO DISCIPLINAR
    -- -----------------------------------------------------------------------------------------------------------------
    IF rec_aluno.formato_id = 1 THEN

        -- caso o aluno já esteja formado, a previsão é o próprio semestre de conclusão
        IF rec_aluno.periodoletivo_conclusao IS NOT NULL THEN
            RETURN rec_aluno.periodoletivo_conclusao;
        END IF;

        -- TODO SQL para identificar a quantidade de créditos a cursar
        SELECT sala FROM gra.sp_historico03_acursar(int_histotico, TRUE) INTO int_creditos_acursar;
        int_creditos_acursar := COALESCE(int_creditos_acursar, 0);

        -- TODO SQL para identificar a quantidade de créditos em curso
        SELECT sala FROM gra.sp_historico03_emcurso(int_histotico, TRUE) INTO int_creditos_emcurso;
        int_creditos_emcurso := COALESCE(int_creditos_emcurso, 0);

        --RAISE NOTICE 'int_creditos_acursar: %', int_creditos_acursar;
        --RAISE NOTICE 'int_creditos_emcurso: %', int_creditos_emcurso;

        -- caso o aluno não possua créditos a cursar, a previsão é o semestre atual
        IF int_creditos_acursar = 0 THEN
            RETURN var_periodo_letivo_atual;
        END IF;

        -- caso o aluno seja de uma forma de ingresso que tenha que respeitar o mínimo de períodos para integralização,
        -- a previsão deverá ser no mímino a quantidade de semestres para atingir a integralização,
        -- levando em consideração os semestres cursados pelo aluno
        IF rec_aluno.formaingresso_id IN (1, 3, 5) THEN

            SELECT COUNT(DISTINCT gra.periodosletivos.label::VARCHAR)
            FROM gra.inscricoes,
                 gra.historicos,
                 gra.matriculas,
                 gra.periodosletivos
            WHERE gra.inscricoes.aluno = par_aluno
              AND gra.historicos.inscricao = gra.inscricoes.codigo
              AND gra.matriculas.historico = gra.historicos.codigo
              AND gra.periodosletivos.codigo = gra.matriculas.periodoletivo
              AND gra.matriculas.status = 1
              AND gra.periodosletivos.label < var_periodo_letivo_atual
              AND gra.periodosletivos.especial = FALSE
            INTO int_periodos_cursados;

            int_minimo_semestre_incrementar := rec_aluno.minperiodosconclusao - int_periodos_cursados;
        END IF;

        -- caso o aluno possua mais créditos do que possa ser cursado em um único semestres,
        -- será subtraído 8 (oito) referente aos créditos "bônus" disponibilizados no último semestre
        IF int_creditos_acursar > rec_aluno.maxcrperiodo THEN
            int_creditos_acursar := int_creditos_acursar - 8;
        END IF;

        -- calculando quantos semestres o aluno precisa cursar para concluir os créditos a cursar
        int_semestres_incrementar := CEIL(int_creditos_acursar / rec_aluno.maxcrperiodo);
        --RAISE NOTICE 'int_semestres_incrementar (CEIL): %', int_semestres_incrementar;

        -- caso o aluno possua disciplinas em curso, será adicionado mais um semestre na previsão
        IF int_creditos_emcurso > 0 THEN
            int_semestres_incrementar := int_semestres_incrementar + 1;
        END IF;

        IF int_minimo_semestre_incrementar > int_semestres_incrementar THEN
            int_semestres_incrementar := int_minimo_semestre_incrementar - 1;
        END IF;

        --RAISE NOTICE 'int_semestres_incrementar: ATUAL + %', int_semestres_incrementar;

        RETURN gra.sp_adiciona_periodos_letivos(var_periodo_letivo_atual, int_semestres_incrementar);

    END IF;
    -- -----------------------------------------------------------------------------------------------------------------

    -- -----------------------------------------------------------------------------------------------------------------
    -- FORMATO MODULAR
    -- -----------------------------------------------------------------------------------------------------------------
    IF rec_aluno.formato_id = 2 THEN
        RETURN '9999-9';
    END IF;
    -- -----------------------------------------------------------------------------------------------------------------

    RETURN NULL;
END;
$$;

--SELECT gra.sp_periodoletivo_conclusao_previsao_nova_regra(125322);
--SELECT gra.sp_periodoletivo_conclusao_previsao_nova_regra(218693);

SELECT bas.pessoas.nome                                                      AS aluno,
       gra.alunos.label                                                      AS matricula,
       gra.cursos.nome                                                       AS curso,
       gra.estruturas.label                                                  AS estrutura,
       gra.formatoestrutura.descricao                                        AS formato,
       gra.sp_periodoletivo_conclusao_previsao_nova_regra(gra.alunos.codigo) AS previsao,
       gra.alunos.codigo                                                     AS aluno_id
FROM gra.alunos,
     gra.inscricoes,
     gra.historicos,
     gra.estruturas,
     gra.habilitacoes,
     gra.cursos,
     gra.formatoestrutura,
     gra.formasdeingressoaluno,
     bas.pessoas
WHERE gra.inscricoes.aluno = gra.alunos.codigo
  AND gra.historicos.inscricao = gra.inscricoes.codigo
  AND gra.historicos.status = 1
  AND gra.estruturas.codigo = gra.historicos.estrutura
  AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
  AND gra.cursos.codigo = gra.habilitacoes.curso
  AND gra.formatoestrutura.codigo = gra.estruturas.formato
  AND gra.formasdeingressoaluno.codigo = gra.alunos.formadeingresso
  AND bas.pessoas.codigo = gra.alunos.pessoa
  AND gra.formatoestrutura.codigo = 1
