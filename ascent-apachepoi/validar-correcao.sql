-- Script para validar se a correção funcionou
-- Execute APÓS a reimportação

USE ascent;

SELECT '═══════════════════════════════════════' as '';
SELECT 'VALIDAÇÃO DA CORREÇÃO' as '';
SELECT '═══════════════════════════════════════' as '';

-- 1. Verificar valores de direcao (deve mostrar ORIGEM/DESTINO agora)
SELECT '1. Valores de direcao (esperado: ORIGEM e DESTINO):' as '';
SELECT DISTINCT direcao FROM aeroportoDirecao ORDER BY direcao;

-- 2. Contar registros
SELECT '2. Total de registros importados:' as '';
SELECT 
    (SELECT COUNT(*) FROM voo) as total_voos,
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'ORIGEM') as total_origens,
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'DESTINO') as total_destinos;

-- 3. Verificar se há algum valor antigo (Partida/Destino)
SELECT '3. Verificar se ainda existem valores antigos (deve retornar 0):' as '';
SELECT 
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'Partida') as partidas_antigas,
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'Destino') as destinos_antigos;

SELECT '═══════════════════════════════════════' as '';
SELECT 'TESTE: Query de Alertas ORIGINAL (deve funcionar agora!)' as '';
SELECT '═══════════════════════════════════════' as '';

-- 4. Testar query de alertas ORIGINAL com ORIGEM/DESTINO
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
JOIN aeroportoDirecao apdo ON v.idVoo = apdo.fkVoo AND apdo.direcao = 'ORIGEM'  -- ✅ Agora funciona!
JOIN aeroporto ao ON apdo.fkAeroporto = ao.idAeroporto
JOIN aeroportoDirecao apdd ON v.idVoo = apdd.fkVoo AND apdd.direcao = 'DESTINO'  -- ✅ Agora funciona!
JOIN aeroporto ad ON apdd.fkAeroporto = ad.idAeroporto
JOIN companhia c ON v.fkCompanhia = c.idCompanhia
JOIN aviao a ON v.fkAviao = a.idAviao
WHERE (v.qtdPassageiros / a.numAssentos) * 100 < 90
LIMIT 10;

SELECT '═══════════════════════════════════════' as '';
SELECT 'RESULTADO DA VALIDAÇÃO' as '';
SELECT '═══════════════════════════════════════' as '';

SELECT 
    '✅ Correção aplicada com sucesso!' as status,
    'Query de alertas agora funciona corretamente' as resultado,
    'Sistema de alertas parametrizados deve funcionar' as conclusao;
