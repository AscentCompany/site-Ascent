-- Script alternativo para adicionar idLogServico
USE ascent;

-- Adicionar coluna sem PRIMARY KEY primeiro
ALTER TABLE logLeitura 
ADD COLUMN idLogServico INT AUTO_INCREMENT UNIQUE FIRST;

-- Verificar
DESCRIBE logLeitura;
SELECT '✓ Coluna idLogServico adicionada!' as resultado;
