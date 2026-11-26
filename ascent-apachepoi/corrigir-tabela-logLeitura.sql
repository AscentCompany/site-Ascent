-- Verificar estrutura atual da tabela logLeitura
USE ascent;

DESCRIBE logLeitura;

-- Se a coluna idLogServico não existir, vamos adicioná-la
-- (isso corrige o erro "Unknown column 'idLogServico'")

-- Primeiro, vamos ver se a tabela tem uma chave primária
SHOW CREATE TABLE logLeitura;

-- Adicionar coluna idLogServico se não existir
ALTER TABLE logLeitura 
ADD COLUMN IF NOT EXISTS idLogServico INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Verificar se foi criada
DESCRIBE logLeitura;

SELECT '✓ Tabela logLeitura corrigida!' as resultado;
