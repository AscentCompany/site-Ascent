-- Verificar dados importados e testar query de alertas
USE ascent;

SELECT '═══════════════════════════════════════' as '';
SELECT 'DADOS IMPORTADOS' as '';
SELECT '═══════════════════════════════════════' as '';

SELECT COUNT(*) as total_voos FROM voo;
SELECT COUNT(*) as total_companhias FROM companhia;
SELECT COUNT(*) as total_aeroportos FROM aeroporto;
SELECT COUNT(*) as total_aeroportos_direcao FROM aeroportoDirecao;

SELECT '═══════════════════════════════════════' as '';
SELECT 'VERIFICAR CAMPO DIRECAO (BUG IDENTIFICADO)' as '';
SELECT '═══════════════════════════════════════' as '';

-- Este é o bug que identificamos: direcao tem 'Partida'/'Destino' mas deveria ser 'ORIGEM'/'DESTINO'
SELECT DISTINCT direcao FROM aeroportoDirecao;

SELECT '═══════════════════════════════════════' as '';
SELECT 'TESTE: Query de Alertas (COM BUG)' as '';
SELECT '═══════════════════════════════════════' as '';

-- Esta query vai FALHAR por causa do bug (não vai retornar dados)
SELECT 
    v.idVoo,
    v.dataPartida,
    ao.nome as aeroporto_origem,
    ad.nome as aeroporto_destino,
    v.ocupacao,
    c.nome as companhia
FROM voo v
JOIN aeroportoDirecao apdo ON v.idVoo = apdo.fkVoo AND apdo.direcao = 'ORIGEM'
JOIN aeroporto ao ON apdo.fkAeroporto = ao.idAeroporto
JOIN aeroportoDirecao apdd ON v.idVoo = apdd.fkVoo AND apdd.direcao = 'DESTINO'
JOIN aeroporto ad ON apdd.fkAeroporto = ad.idAeroporto
JOIN companhia c ON v.fkCompanhia = c.idCompanhia
WHERE v.ocupacao < 90
LIMIT 5;

SELECT '═══════════════════════════════════════' as '';
SELECT 'TESTE: Query de Alertas (CORRIGIDA - com Partida/Destino)' as '';
SELECT '═══════════════════════════════════════' as '';

-- Esta query vai FUNCIONAR usando os valores reais
SELECT 
    v.idVoo,
    v.dataPartida,
    ao.nome as aeroporto_origem,
    ad.nome as aeroporto_destino,
    v.ocupacao,
    c.nome as companhia
FROM voo v
JOIN aeroportoDirecao apdo ON v.idVoo = apdo.fkVoo AND apdo.direcao = 'Partida'
JOIN aeroporto ao ON apdo.fkAeroporto = ao.idAeroporto
JOIN aeroportoDirecao apdd ON v.idVoo = apdd.fkVoo AND apdd.direcao = 'Destino'
JOIN aeroporto ad ON apdd.fkAeroporto = ad.idAeroporto
JOIN companhia c ON v.fkCompanhia = c.idCompanhia
WHERE v.ocupacao < 90
LIMIT 5;

SELECT '═══════════════════════════════════════' as '';
SELECT 'RESUMO' as '';
SELECT '═══════════════════════════════════════' as '';

SELECT 
    'Dados importados com sucesso!' as status,
    'Bug confirmado: direcao usa Partida/Destino ao invés de ORIGEM/DESTINO' as problema,
    'Sistema de alertas NÃO funcionará até corrigir o bug' as impacto;
