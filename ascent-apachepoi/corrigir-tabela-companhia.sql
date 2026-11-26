-- Corrigir tabela companhia para permitir fkCargo NULL
USE ascent;

-- Ver estrutura atual
DESCRIBE companhia;

-- Permitir que fkCargo seja NULL (já que a importação não tem esse dado)
ALTER TABLE companhia MODIFY COLUMN fkCargo INT NULL;

-- Verificar mudança
DESCRIBE companhia;

SELECT '✓ Tabela companhia corrigida - fkCargo agora aceita NULL!' as resultado;
