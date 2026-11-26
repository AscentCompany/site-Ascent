-- Script para corrigir a tabela logLeitura
USE ascent;

-- Opção 1: Se a tabela não tem PRIMARY KEY, adicionar idLogServico
-- Verificar se já existe a coluna
SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'ascent' 
    AND TABLE_NAME = 'logLeitura' 
    AND COLUMN_NAME = 'idLogServico'
);

-- Se não existe, criar a coluna
-- Primeiro, vamos tentar remover a PRIMARY KEY se existir em outra coluna
ALTER TABLE logLeitura DROP PRIMARY KEY;

-- Agora adicionar a coluna idLogServico como PRIMARY KEY
ALTER TABLE logLeitura 
ADD COLUMN idLogServico INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Verificar resultado
DESCRIBE logLeitura;
SELECT '✓ Coluna idLogServico adicionada com sucesso!' as resultado;
