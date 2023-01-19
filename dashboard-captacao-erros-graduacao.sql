/*
SELECT *
FROM gerencial.db_captacao_alunos
WHERE gerencial.db_captacao_alunos.captacao_configuracao = 33
  --AND (captacao_oferta IS NULL AND captacao_statusaluno = 2)
  --AND (captacao_oferta IS NULL AND formaingresso IS NULL)
  --AND (matricula = 'CPF NÃO ENCONTRADO' AND captacao_statusaluno = 2)
  --AND (captacao_oferta IS NOT NULL AND captacao_formaingresso IS NULL)
    -- CRIACAO DE NOVOS STATUS [LEAD]- [PRE-INICIADO] - INICIADO - CONCLUIDO
    -- indicacoes iniciadas que não estão do dashboard
*/
