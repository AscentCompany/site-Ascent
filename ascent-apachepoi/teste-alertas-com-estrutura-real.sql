-- Teste de alertas com a estrutura REAL do banco
USE ascent;

SELECT '═══════════════════════════════════════' as '';
SELECT 'TESTE: Query de Alertas (ESTRUTURA REAL)' as '';
SELECT '═══════════════════════════════════════' as '';

-- Query que DEVERIA funcionar (calculando ocupação em tempo real)
SELECT 
    v.idVoo,
    v.numVoo,
    ao.nomeAeroporto as aeroporto_origem,
    ad.nomeAeroporto as aeroporto_destino,
    apdo.dia as data_partida,
    apdo.hora as hora_partida,
    v.qtdPassageiros,
    a.numAssentos,
    ROUND((v.qtdPassageiros / a.numAssentos) * 100, 2) as ocupacao_calculada,
    c.nomeCompanhia as companhia
FROM voo v
JOIN aeroportoDirecao apdo ON v.idVoo = apdo.fkVoo AND apdo.direcao = 'Partida'
JOIN aeroporto ao ON apdo.fkAeroporto = ao.idAeroporto
JOIN aeroportoDirecao apdd ON v.idVoo = apdd.fkVoo AND apdd.direcao = 'Destino'
JOIN aeroporto ad ON apdd.fkAeroporto = ad.idAeroporto
JOIN companhia c ON v.fkCompanhia = c.idCompanhia
JOIN aviao a ON v.fkAviao = a.idAviao
WHERE (v.qtdPassageiros / a.numAssentos) * 100 < 90
LIMIT 10;

SELECT '═══════════════════════════════════════' as '';
SELECT 'RESUMO DO DIAGNÓSTICO' as '';
SELECT '═══════════════════════════════════════' as '';

SELECT 
    '✅ Importação concluída: 120.241 voos' as status
UNION ALL
SELECT 
    '⚠️ Bug confirmado: direcao = Partida/Destino (esperado: ORIGEM/DESTINO)'
UNION ALL
SELECT 
    '⚠️ Tabela voo NÃO TEM campo ocupacao - precisa calcular: (qtdPassageiros/numAssentos)*100'
UNION ALL
SELECT 
    '❌ Sistema de alertas NÃO funcionará até corrigir:'
UNION ALL
SELECT 
    '   1. Campo direcao em LeitorExcel.java (linhas 249, 258)'
UNION ALL
SELECT 
    '   2. Query de alertas precisa calcular ocupacao dinamicamente';
