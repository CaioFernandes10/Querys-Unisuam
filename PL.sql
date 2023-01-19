CREATE OR REPLACE FUNCTION gra.sp_retorna_dados_diploma(par_cpf VARCHAR, par_data_nascimento VARCHAR,
                                                        par_token_diploma VARCHAR)
    RETURNS gra.tp_dados_diploma
    LANGUAGE plpgsql
AS
$$
DECLARE
    rec_retorno       gra.tp_dados_diploma;
    rec_dados_diploma RECORD;
BEGIN

    SELECT DISTINCT diploma.alunos_dados_pessoais.nome                                                               AS nome_aluno,
                    TO_CHAR(diploma.alunos_dados_pessoais.datanascimento::DATE,
                            'DD/MM/YYYY')                                                                            AS data_nascimento,
                    diploma.sp_cpf(diploma.alunos.codigo, true)                                                      AS cpf,
                    (SELECT numero FROM diploma.sp_rg(diploma.alunos.codigo))                                        AS rg,
                    CASE diploma.alunos_dados_pessoais.sexo
                        WHEN 'M' THEN 'Masculino'
                        WHEN 'F' THEN 'Feminino'
                        ELSE 'NAO INFORMADO' END                                                                     AS sexo,
                    diploma.alunos_dados_pessoais.nacionalidade                                                      AS nacionalidade,
                    diploma.naturalidades.municipio || ' / ' ||
                    diploma.naturalidades.estado                                                                     AS estado,
                    TO_CHAR(diploma.alunos.data_colacao::DATE,
                            'DD/MM/YYYY')                                                                            AS data_colacao_aluno,
                    diploma.cursos.nome                                                                              AS curso_nome,
                    diploma.status_processos.descricao                                                               AS status_diploma,
                    diploma.cursos.mec_id                                                                            AS curso_codigo_mec,
                    diploma.cursos.habilitacao                                                                       AS curso_habilitacao,
                    diploma.modalidadescurso.descricao                                                               AS curso_modalidade,
                    diploma.cursos.titulo                                                                            AS curso_titulo,
                    diploma.cursos.grau                                                                              AS curso_grau,
                    diploma.enderecos.logradouro || ' nº' || diploma.enderecos.numero
                        || ' - ' || diploma.enderecos.bairro || ' - ' || diploma.enderecos.localidade || ' / ' ||
                    diploma.enderecos.estado                                                                         AS curso_endereco,
                    (string_to_array(diploma.ies.nome, '-'))[array_upper(string_to_array(diploma.ies.nome, '-'), 1)] AS polo,
                    diploma.sp_autorizacao(diploma.cursos.codigo, diploma.ies.codigo)                                AS curso_autorizacao,
                    diploma.sp_reconhecimento(diploma.cursos.codigo,
                                              diploma.ies.codigo)                                                    AS curso_reconhecimento,
                    'MOCK'                                                                                           AS curso_renovacao_reconhecimento,
                    diploma.ies.razao_social                                                                         AS ies_nome,
                    diploma.ies.mec_id                                                                               AS ies_codigo_mec,
                    diploma.ies.cnpj                                                                                 AS ies_cnpj,
                    gra.sp_retorna_credenciamentos(diploma.cursos.modalidade, FALSE,
                                                   'DD/MM/YYYY')                                                     AS ies_credenciamento,
                    gra.sp_retorna_credenciamentos(diploma.cursos.modalidade, TRUE,
                                                   'DD/MM/YYYY')                                                     AS ies_recredenciamento,
                    mantenedora.razao_social || ' - ' || mantenedora.cnpj                                            AS mantenedora,
                    diploma.registro_academico.numero_processo_diploma                                               AS numero_processo_diploma,
                    diploma.registro_academico.numero_registro                                                       AS numero_registro_diploma,
                    diploma.registro_academico.nome_responsavel_registro                                             AS responsavel_registro_diploma,
                    TO_CHAR(diploma.registro_academico.updated_at::DATE,
                            'DD/MM/YYYY')                                                                            AS data_registro,
                    (SELECT TO_CHAR(MAX(documentos_assinados.updated_at):: DATE, 'DD/MM/YYYY')
                     FROM diploma.documentos_assinados,
                          diploma.documentos AS diploma_dip
                     WHERE diploma_dip.codigo = diploma.documentos_assinados.documento
                       AND diploma_dip.codigo = diploma.documentos.codigo)                                           AS data_expedicao,
                    diploma.alunos.codigo                                                                            AS id
    FROM diploma.alunos,
         diploma.alunos_dados_pessoais,
         diploma.registro_academico,
         diploma.processos,
         diploma.status_processos,
         diploma.enderecos,
         diploma.ies,
         diploma.ies AS mantenedora,
         diploma.cursos,
         diploma.modalidadescurso,
         diploma.naturalidades,
         diploma.alunos_documentos,
         diploma.documentos_arquivos,
         diploma.documentos
    WHERE diploma.alunos_dados_pessoais.codigo = diploma.alunos.dados_pessoais_id
      AND diploma.registro_academico.aluno_id = diploma.alunos.codigo
      AND diploma.processos.registro_academico = diploma.registro_academico.codigo
      AND diploma.status_processos.codigo = diploma.processos.status
      AND diploma.ies.codigo = diploma.alunos.ies_id
      AND diploma.cursos.codigo = diploma.alunos.curso_id
      AND diploma.enderecos.codigo = diploma.ies.endereco_id
      AND diploma.modalidadescurso.codigo = diploma.cursos.modalidade
      AND mantenedora.codigo = diploma.ies.mantenedora_id
      AND diploma.naturalidades.codigo = diploma.alunos_dados_pessoais.naturalidade_id
      AND diploma.alunos_documentos.aluno = diploma.alunos.codigo
      AND diploma.documentos_arquivos.documento = diploma.alunos_documentos.documento
      AND diploma.processos.status = 4
      AND diploma.documentos.codigo = diploma.documentos_arquivos.documento
      AND diploma.documentos.tipo = 159
      AND diploma.documentos.pdf = FALSE
      AND diploma.documentos.status IN (1, 2)
      AND (
                    diploma.sp_cpf(diploma.alunos.codigo, false) = par_cpf
                AND TO_CHAR(diploma.alunos_dados_pessoais.datanascimento::DATE, 'ddmmyyyy') = par_data_nascimento
            OR diploma.documentos_arquivos.token = par_token_diploma
        )
    INTO rec_dados_diploma;

    IF FOUND THEN
        rec_retorno.nome := rec_dados_diploma.nome_aluno;
        rec_retorno.data_nascimento := rec_dados_diploma.data_nascimento;
        rec_retorno.cpf := rec_dados_diploma.cpf;
        rec_retorno.rg := rec_dados_diploma.rg;
        rec_retorno.sexo := rec_dados_diploma.sexo;
        rec_retorno.nacionalidade := rec_dados_diploma.nacionalidade;
        rec_retorno.estado := rec_dados_diploma.estado;
        rec_retorno.data_colacao := rec_dados_diploma.data_colacao_aluno;
        rec_retorno.curso := rec_dados_diploma.curso_nome;
        rec_retorno.curso_codigo_mec := rec_dados_diploma.curso_codigo_mec;
        rec_retorno.curso_habilitacao := rec_dados_diploma.curso_habilitacao;
        rec_retorno.curso_modalidade := rec_dados_diploma.curso_modalidade;
        rec_retorno.curso_titulo := rec_dados_diploma.curso_titulo;
        rec_retorno.curso_grau := rec_dados_diploma.curso_grau;
        rec_retorno.curso_endereco := rec_dados_diploma.curso_endereco;
        rec_retorno.curso_autorizacao := rec_dados_diploma.curso_autorizacao;
        rec_retorno.curso_reconhecimento := rec_dados_diploma.curso_reconhecimento;
        rec_retorno.curso_renovacao_reconhecimento := rec_dados_diploma.curso_renovacao_reconhecimento;
        rec_retorno.ies_nome := rec_dados_diploma.ies_nome;
        rec_retorno.ies_codigo_mec := rec_dados_diploma.ies_codigo_mec;
        rec_retorno.ies_cnpj := rec_dados_diploma.ies_cnpj;
        rec_retorno.ies_credenciamento := rec_dados_diploma.ies_credenciamento;
        rec_retorno.ies_recredenciamento := rec_dados_diploma.ies_recredenciamento;
        rec_retorno.mantenedora := rec_dados_diploma.mantenedora;
        rec_retorno.polo := rec_dados_diploma.polo;
        rec_retorno.numero_processo_diploma := rec_dados_diploma.numero_processo_diploma;
        rec_retorno.numero_registro_diploma := rec_dados_diploma.responsavel_registro_diploma;
        rec_retorno.responsavel_registro_diploma := rec_dados_diploma.responsavel_registro_diploma;
        rec_retorno.status_diploma := rec_dados_diploma.status_diploma;
        rec_retorno.data_registro := rec_dados_diploma.data_registro;
        rec_retorno.data_expedicao := rec_dados_diploma.data_expedicao;
        rec_retorno.id := rec_dados_diploma.id;
        RETURN rec_retorno;
    END IF;

    SELECT bas.pessoas.nome                                                                                           AS nome_aluno,
           TO_CHAR(bas.pessoas.nascimentodata, 'DD/MM/YYYY')                                                          AS data_nascimento,
           bas.sp_cpf(bas.pessoas.codigo, FALSE)                                                                      AS cpf,
           bas.documentos.campotexto1                                                                                 AS rg,
           CASE bas.pessoas.sexo
               WHEN 'M' THEN 'Masculino'
               WHEN 'F' THEN 'Feminino'
               ELSE 'NAO INFORMADO' END                                                                               AS sexo,
           bas.paises.nacionalidade,
           bas.localidades.descricao || ' / ' || bas.estados.descricao                                                AS estado,
           (
               SELECT gra.inep.inep
               FROM gra.inep
               WHERE gra.inep.habilitacao = gra.habilitacoes.codigo
                 AND gra.inep.unidade = gra.inscricoes.unidade_unid
           )                                                                                                          AS curso_codigo_mec,
           gra.cursos.nome                                                                                            AS curso_nome,
           gra.habilitacoes.descricao                                                                                 AS curso_habilitacao,
           gra.modalidadescurso.descricao                                                                             AS curso_modalidade,
           gra.tiposgrau.descricao                                                                                    AS curso_grau,
           gra.tipostitulo.descricao                                                                                  AS curso_titulo,
           'ATIVO'                                                                                                    as status_diploma,
           bas.tiposlogradouro.descricao || bas.logradouros.descricao || ' nº' || bas.enderecos.numero
               || ' - ' || bas.bairros.descricao || ' - ' || unidade_localidade.descricao || ' / ' ||
           unidade_estado.descricao                                                                                   AS curso_endereco,
           (string_to_array(bas.unidades.nomesite, '-'))[array_upper(string_to_array(bas.unidades.nomesite, '-'), 1)] AS polo,
           gra.sp_retorna_reconhecimentos(gra.habilitacoes.codigo, bas.unidades.codigo,
                                          2)                                                                          AS curso_autorizacao,
           gra.sp_retorna_reconhecimentos(gra.habilitacoes.codigo, bas.unidades.codigo,
                                          3)                                                                          AS curso_reconhecimento,
           'MOCK'                                                                                                     AS curso_renovacao_reconhecimento,
           '277'                                                                                                      AS ies_codigo_mec,
           'Sociedade Unificada Augusto Motta'                                                                        AS ies_nome,
           '34008227000103'                                                                                           AS ies_cnpj,
           gra.sp_retorna_credenciamentos(gra.cursos.modalidade, FALSE,
                                          'DD/MM/YYYY')                                                               AS ies_credenciamento,
           gra.sp_retorna_credenciamentos(gra.cursos.modalidade, TRUE,
                                          'DD/MM/YYYY')                                                               AS ies_recredenciamento,
           mantenedora.razaosocial || ' - ' || '34008227000103'                                                       AS mantenedora,
           TO_CHAR((
                       SELECT MIN(gra.inscricoes.dataregistro)
                       FROM gra.inscricoes
                       WHERE gra.inscricoes.aluno = gra.alunos.codigo
                   ),
                   'DD/MM/YYYY')                                                                                      AS data_ingresso,
           TO_CHAR(gra.inscricoes.datacolacaograu, 'DD/MM/YYYY')                                                      AS data_colacao_aluno,
           TO_CHAR(gra.registrosdiploma.dataregistro, 'DD/MM/YYYY')                                                   AS data_expedicao,
           TO_CHAR(gra.registrosdiploma.dataregistro, 'DD/MM/YYYY')                                                   AS data_registro,
           TO_CHAR(datapublicacao, 'DD/MM/YYYY')                                                                      AS data_publicacao,
           gra.registrosdiploma.processo                                                                              AS numero_processo_diploma,
           gra.registrosdiploma.registro                                                                              AS responsavel_registro_diploma,
           gra.alunos.codigo                                                                                          AS id
    FROM gra.historicos,
         gra.inscricoes,
         gra.alunos,
         bas.pessoas,
         gra.estruturas,
         gra.habilitacoes,
         gra.cursos,
         (
             SELECT inscricao, MAX(processo) AS processo
             FROM gra.registrosdiploma
             GROUP BY 1
         ) registros,
         gra.registrosdiploma,
         bas.pessoas_documentos,
         bas.documentos,
         bas.paises,
         bas.estados,
         bas.localidades,
         gra.modalidadescurso,
         gra.tipostitulo,
         gra.tiposgrau,
         bas.unidades,
         bas.empresas,
         bas.empresas_enderecos,
         bas.enderecos,
         bas.logradouros,
         bas.tiposlogradouro,
         bas.bairros,
         bas.estados as unidade_estado,
         bas.localidades as unidade_localidade,
         bas.empresas as mantenedora
    WHERE gra.historicos.status = 2
      AND gra.inscricoes.codigo = gra.historicos.inscricao
      AND gra.alunos.codigo = gra.inscricoes.aluno
      AND bas.pessoas.codigo = gra.alunos.pessoa
      AND TO_CHAR(bas.pessoas.nascimentodata, 'ddmmyyyy') = par_data_nascimento
      AND bas.sp_cpf(bas.pessoas.codigo, FALSE) = par_cpf
      AND gra.estruturas.codigo = gra.historicos.estrutura
      AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
      AND gra.cursos.codigo = gra.habilitacoes.curso
      AND registros.inscricao = gra.inscricoes.codigo
      AND gra.modalidadescurso.codigo = gra.cursos.modalidade
      AND gra.registrosdiploma.processo = registros.processo
      AND bas.pessoas_documentos.pessoa = bas.pessoas.codigo
      AND bas.pessoas_documentos.documento = bas.documentos.codigo
      AND gra.habilitacoes.titulo = gra.tipostitulo.codigo
      AND gra.habilitacoes.grau = gra.tiposgrau.codigo
      AND bas.unidades.codigo = gra.inscricoes.unidade_unid
      AND bas.empresas.codigo = bas.unidades.empresa
      AND bas.empresas_enderecos.empresa = bas.empresas.codigo
      AND bas.enderecos.codigo = bas.empresas_enderecos.endereco
      AND bas.logradouros.codigo = bas.enderecos.logradouro
      AND bas.bairros.codigo = bas.enderecos.bairro
      AND unidade_estado.codigo = bas.enderecos.estado
      AND unidade_localidade.codigo = bas.enderecos.localidade
      AND bas.paises.codigo = bas.pessoas.nascimentopais
      AND bas.estados.codigo = bas.pessoas.nascimentoestado
      AND bas.localidades.codigo = bas.pessoas.nascimentocidade
      AND bas.tiposlogradouro.codigo = bas.enderecos.tipologradouro
      AND mantenedora.codigo = bas.unidades.mantenedora
      AND bas.documentos.tipo = 2
      AND gra.registrosdiploma.datapublicacao IS NOT NULL
    INTO rec_dados_diploma;


    IF FOUND THEN
        rec_retorno.nome := rec_dados_diploma.nome_aluno;
        rec_retorno.data_nascimento := rec_dados_diploma.data_nascimento;
        rec_retorno.cpf := rec_dados_diploma.cpf;
        rec_retorno.rg := rec_dados_diploma.rg;
        rec_retorno.sexo := rec_dados_diploma.sexo;
        rec_retorno.nacionalidade := rec_dados_diploma.nacionalidade;
        rec_retorno.estado := rec_dados_diploma.estado;
        rec_retorno.data_colacao := rec_dados_diploma.data_colacao_aluno;
        rec_retorno.curso := rec_dados_diploma.curso_nome;
        rec_retorno.curso_codigo_mec := rec_dados_diploma.curso_codigo_mec;
        rec_retorno.curso_habilitacao := rec_dados_diploma.curso_habilitacao;
        rec_retorno.curso_modalidade := rec_dados_diploma.curso_modalidade;
        rec_retorno.curso_titulo := rec_dados_diploma.curso_titulo;
        rec_retorno.curso_grau := rec_dados_diploma.curso_grau;
        rec_retorno.curso_endereco := rec_dados_diploma.curso_endereco;
        rec_retorno.curso_autorizacao := rec_dados_diploma.curso_autorizacao;
        rec_retorno.curso_reconhecimento := rec_dados_diploma.curso_reconhecimento;
        rec_retorno.curso_renovacao_reconhecimento := rec_dados_diploma.curso_renovacao_reconhecimento;
        rec_retorno.ies_nome := rec_dados_diploma.ies_nome;
        rec_retorno.ies_codigo_mec := rec_dados_diploma.ies_codigo_mec;
        rec_retorno.ies_cnpj := rec_dados_diploma.ies_cnpj;
        rec_retorno.ies_credenciamento := rec_dados_diploma.ies_credenciamento;
        rec_retorno.ies_recredenciamento := rec_dados_diploma.ies_recredenciamento;
        rec_retorno.mantenedora := rec_dados_diploma.mantenedora;
        rec_retorno.polo := rec_dados_diploma.polo;
        rec_retorno.numero_processo_diploma := rec_dados_diploma.numero_processo_diploma;
        rec_retorno.numero_registro_diploma := rec_dados_diploma.responsavel_registro_diploma;
        rec_retorno.responsavel_registro_diploma := rec_dados_diploma.responsavel_registro_diploma;
        rec_retorno.status_diploma := rec_dados_diploma.status_diploma;
        rec_retorno.data_registro := rec_dados_diploma.data_registro;
        rec_retorno.data_expedicao := rec_dados_diploma.data_expedicao;
        rec_retorno.id := rec_dados_diploma.id;
        RETURN rec_retorno;
    END IF;
    RETURN rec_retorno;
END
$$;