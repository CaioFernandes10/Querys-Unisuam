SELECT sis.categoriaprocessobatch.descricao,
       sis.processobatch.descricao,
       MAX(sis.processobatch.dataexecucao),
       COUNT(*)
FROM sis.processobatch,
     sis.categoriaprocessobatch
WHERE sis.categoriaprocessobatch.codigo = sis.processobatch.categoria
AND sis.processobatch.dataexecucao >= '2022-11-10'::DATE
GROUP BY 1, 2
ORDER BY 3;


/*
Verificar boletos cog	                    TESTSQL1	                                                            2016-10-24 18:18:08.152045
Processo EAD Moodle	                        Criando backup de turma hibrida	                                        2017-02-13 15:58:15.903928
Processo EAD Moodle	                        Criar Processo para inclus�o da turma m�e no Moodle - Segunda tentativa	2017-02-13 18:44:57.524631
Regua Cog	                                Inscri��o no Curso Online Gratuito	                                    2017-08-17 18:55:09.146261
SGP	                                        PROCESSO ATUALIZACAO EM MASSA	                                        2018-11-07 14:39:08.872617
Regua Cog	                                Criar Processo disparo de regua matriculado	                            2019-01-10 17:41:32.796780
Regua Cog	                                Criar Processo disparo de regua matriculado trinta dias	                2019-02-09 11:32:21.469349
Processo EAD Moodle	                        Criar Processo para inclus�o da turma m�e no Moodle	                    2019-07-10 23:38:43.677975
R�gua de Relacionamento	                    R�gua de relacionamento - Status do boleto por modalidade da extens�o	2019-11-08 13:33:31.964995
Processo Inscri��o no Processo Seletivo	    VestibularNecessidadeEspecial	                                        2020-05-17 22:07:20.701705
----------------------------------------------------------------------------------------------------------------------------------------------
R�gua de Relacionamento	                    Lembrete de Devolu��o de Livro - Processo	                            2022-04-07 11:21:41.139984
R�gua de Relacionamento	                    Lembrete de Devolu��o de Livro	                                        2022-04-07 13:43:11.192009
Falta da Pos	                            PROCESSO DE LAN�AMENTO DE FALTA	                                        2022-04-07 17:07:41.331445
Pagamento Online	                        Comprovante de Pagamento Online	                                        2022-04-07 17:13:04.634491
R�gua de Relacionamento	                    R�gua de relacionamento - Status do boleto por tipo de servi�o	        2022-04-07 17:17:29.264323
R�gua de Relacionamento	                    R�gua de relacionamento - Processo da biblioteca	                    2022-04-07 17:22:52.875311
----------------------------------------------------------------------------------------------------------------------------------------------
Verificar boletos cog	                    VERIFICAR BOLETOS COG	                                                2022-04-07 16:45:52.939254
CRM	                                        Processo CRM	                                                        2022-04-07 17:08:52.772227
Processo EAD Moodle	                        Criar processo para exclus�o de alunos no curso do moodle	            2022-04-07 14:58:29.247224
----------------------------------------------------------------------------------------------------------------------------------------------
*/

