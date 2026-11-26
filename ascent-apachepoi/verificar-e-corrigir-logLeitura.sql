-- Verificar estrutura completa da tabela logLeitura
USE ascent;

-- Ver estrutura atual
SHOW CREATE TABLE logLeitura;

-- Ver todas as colunas
DESCRIBE logLeitura;

-- Contar registros
SELECT COUNT(*) as total_registros FROM logLeitura;
