-- Script para limpar dados antigos e preparar para reimportação
-- Execute ANTES de rodar a importação com código corrigido

USE ascent;

SELECT '═══════════════════════════════════════' as '';
SELECT 'LIMPANDO DADOS ANTIGOS' as '';
SELECT '═══════════════════════════════════════' as '';

-- Desabilitar verificação de chaves estrangeiras temporariamente
SET FOREIGN_KEY_CHECKS = 0;

-- Desabilitar safe update mode temporariamente
SET SQL_SAFE_UPDATES = 0;

-- Contar antes de deletar
SELECT 
    (SELECT COUNT(*) FROM voo) as voos_antes_delete,
    (SELECT COUNT(*) FROM aeroportoDirecao) as direcoes_antes_delete,
    (SELECT COUNT(*) FROM logsServico WHERE servico = 'importacao') as logs_antes_delete;

-- Limpar dados com valores antigos (Partida/Destino)
DELETE FROM aeroportoDirecao;
DELETE FROM voo;
DELETE FROM logsServico WHERE servico = 'importacao';

-- Resetar auto-increment
ALTER TABLE voo AUTO_INCREMENT = 1;

-- Reabilitar verificação de chaves estrangeiras
SET FOREIGN_KEY_CHECKS = 1;

-- Reabilitar safe update mode
SET SQL_SAFE_UPDATES = 1;

SELECT '═══════════════════════════════════════' as '';
SELECT 'LIMPEZA CONCLUÍDA' as '';
SELECT '═══════════════════════════════════════' as '';

-- Confirmar limpeza
SELECT 
    (SELECT COUNT(*) FROM voo) as voos_apos_delete,
    (SELECT COUNT(*) FROM aeroportoDirecao) as direcoes_apos_delete,
    (SELECT COUNT(*) FROM logsServico WHERE servico = 'importacao') as logs_apos_delete;

SELECT '✓ Banco limpo e pronto para reimportação com código corrigido!' as status;
