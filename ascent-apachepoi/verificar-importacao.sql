-- Verificar se a importação foi executada
USE ascent;

SELECT 'VERIFICAÇÃO DA IMPORTAÇÃO' as '═══════════════════════════════';

SELECT COUNT(*) as total_voos FROM voo;
SELECT COUNT(*) as total_companhias FROM companhia;
SELECT COUNT(*) as total_aeroportos FROM aeroporto;
SELECT COUNT(*) as total_direcoes FROM aeroportoDirecao;

SELECT '═══════════════════════════════' as '';

-- Verificar log de importação
SELECT * FROM logLeitura ORDER BY dataHora DESC LIMIT 5;
