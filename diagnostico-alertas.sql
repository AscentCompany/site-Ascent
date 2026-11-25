-- =============================================================
-- Script de Diagnóstico - Sistema de Alertas Ascent
-- =============================================================
-- Este script verifica o estado do banco de dados para identificar
-- por que os alertas não estão sendo gerados.
--
-- Execute este script primeiro para entender o problema.
-- =============================================================

SELECT '=== DIAGNÓSTICO DO BANCO DE DADOS ===' AS '';

-- -------------------------------------------------------------
-- 1. VERIFICAR ESTRUTURA DAS TABELAS (Schema)
-- -------------------------------------------------------------
SELECT '1. ESTRUTURA DAS TABELAS' AS '';

DESCRIBE voo;
DESCRIBE aeroporto;
DESCRIBE aeroportoDirecao;
DESCRIBE aviao;
DESCRIBE companhia;
DESCRIBE regraAlerta;
DESCRIBE alerta;

-- -------------------------------------------------------------
-- 2. VERIFICAR SE HÁ DADOS NO BANCO
-- -------------------------------------------------------------
SELECT '2. CONTAGEM DE REGISTROS' AS '';

SELECT 'Voos' AS tabela, COUNT(*) AS total FROM voo
UNION ALL
SELECT 'Aeroportos', COUNT(*) FROM aeroporto
UNION ALL
SELECT 'Aviões', COUNT(*) FROM aviao
UNION ALL
SELECT 'Companhias', COUNT(*) FROM companhia
UNION ALL
SELECT 'Aeroporto Direções', COUNT(*) FROM aeroportoDirecao
UNION ALL
SELECT 'Regras de Alerta', COUNT(*) FROM regraAlerta
UNION ALL
SELECT 'Alertas Gerados', COUNT(*) FROM alerta;

-- -------------------------------------------------------------
-- 3. DISTRIBUIÇÃO DE VOOS POR COMPANHIA
-- -------------------------------------------------------------
SELECT '3. VOOS POR COMPANHIA' AS '';

SELECT 
    c.idCompanhia,
    c.codCompanhia,
    c.nomeCompanhia,
    COUNT(v.idVoo) AS total_voos
FROM companhia c
LEFT JOIN voo v ON v.fkCompanhia = c.idCompanhia
GROUP BY c.idCompanhia, c.codCompanhia, c.nomeCompanhia
ORDER BY total_voos DESC
LIMIT 10;

-- -------------------------------------------------------------
-- 4. VERIFICAR DADOS DE OCUPAÇÃO (essencial para alertas)
-- -------------------------------------------------------------
SELECT '4. DADOS DE OCUPAÇÃO' AS '';

SELECT 
    COUNT(*) AS voos_com_passageiros,
    COUNT(CASE WHEN qtdPassageiros > 0 THEN 1 END) AS voos_com_passageiros_positivos
FROM voo
WHERE qtdPassageiros IS NOT NULL;

SELECT 
    COUNT(*) AS avioes_com_assentos,
    COUNT(CASE WHEN numAssentos > 0 THEN 1 END) AS avioes_com_assentos_positivos
FROM aviao;

-- -------------------------------------------------------------
-- 5. VERIFICAR REGRAS DE ALERTA CRIADAS
-- -------------------------------------------------------------
SELECT '5. REGRAS DE ALERTA CONFIGURADAS' AS '';

SELECT 
    r.idRegraAlerta,
    r.faixaOcupacao,
    r.severidade,
    r.janelaAnalise,
    r.janelaInicio,
    r.janelaFim,
    r.ativo,
    r.fkCompanhia,
    c.nomeCompanhia,
    r.dataCriacao
FROM regraAlerta r
JOIN companhia c ON c.idCompanhia = r.fkCompanhia
WHERE r.fkCompanhia IN (1, 2)
ORDER BY r.dataCriacao DESC;

-- -------------------------------------------------------------
-- 6. VERIFICAR ALERTAS GERADOS
-- -------------------------------------------------------------
SELECT '6. ALERTAS GERADOS' AS '';

SELECT 
    a.idAlerta,
    a.origemIata,
    a.destinoIata,
    a.ocupacaoMedia,
    a.severidade,
    a.lida,
    a.fkCompanhia,
    c.nomeCompanhia,
    a.dataCriacao
FROM alerta a
JOIN companhia c ON c.idCompanhia = a.fkCompanhia
WHERE a.fkCompanhia IN (1, 2)
ORDER BY a.dataCriacao DESC
LIMIT 20;

-- -------------------------------------------------------------
-- 7. AMOSTRA DE DADOS IMPORTADOS (se houver)
-- -------------------------------------------------------------
SELECT '7. AMOSTRA DE VOOS (primeiros 10)' AS '';

SELECT 
    v.idVoo,
    v.numVoo,
    v.qtdPassageiros,
    av.numAssentos,
    ROUND(100.0 * v.qtdPassageiros / NULLIF(av.numAssentos, 0), 2) AS ocupacao_pct,
    c.nomeCompanhia,
    ao.uf AS origem_uf,
    ad.uf AS destino_uf,
    adp.dia AS data_voo
FROM voo v
LEFT JOIN companhia c ON c.idCompanhia = v.fkCompanhia
LEFT JOIN aviao av ON av.idAviao = v.fkAviao
LEFT JOIN aeroportoDirecao adp ON adp.fkVoo = v.idVoo AND adp.direcao = 'Partida'
LEFT JOIN aeroportoDirecao add ON add.fkVoo = v.idVoo AND add.direcao = 'Destino'
LEFT JOIN aeroporto ao ON ao.idAeroporto = adp.fkAeroporto
LEFT JOIN aeroporto ad ON ad.idAeroporto = add.fkAeroporto
LIMIT 10;

-- -------------------------------------------------------------
-- 8. TESTE DA QUERY DE PROCESSAMENTO DE ALERTAS
-- -------------------------------------------------------------
SELECT '8. SIMULAÇÃO DA QUERY DE ALERTAS (ocupação < 90%)' AS '';

SELECT 
    ao.uf AS origemIata, 
    ad2.uf AS destinoIata,
    ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia,
    COUNT(v.idVoo) AS total_voos
FROM voo v
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'
JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
JOIN aviao av ON av.idAviao = v.fkAviao
WHERE v.fkCompanhia = 1 -- Ajustar para sua companhia
  AND v.qtdPassageiros IS NOT NULL 
  AND av.numAssentos > 0
GROUP BY ao.uf, ad2.uf
HAVING ocupacaoMedia < 90
ORDER BY ocupacaoMedia ASC
LIMIT 10;

-- -------------------------------------------------------------
-- 9. VERIFICAR LOGS DE IMPORTAÇÃO (se existirem)
-- -------------------------------------------------------------
SELECT '9. LOGS DE IMPORTAÇÃO (últimos 10)' AS '';

SELECT 
    idLogLeitura,
    categoria,
    servico,
    mensagem,
    dataHora,
    nomeArquivo,
    statusLeitura,
    linhasEncontradas,
    linhasLidas,
    linhasRejeitadas
FROM logLeitura
ORDER BY dataHora DESC
LIMIT 10;

-- -------------------------------------------------------------
-- RESUMO DO DIAGNÓSTICO
-- -------------------------------------------------------------
SELECT '=== RESUMO DO DIAGNÓSTICO ===' AS '';

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM voo) = 0 THEN 
            '❌ PROBLEMA: Nenhum voo no banco de dados. É necessário importar os arquivos Excel.'
        WHEN (SELECT COUNT(*) FROM voo WHERE fkCompanhia IN (1,2)) = 0 THEN
            '⚠️ PROBLEMA: Há voos no banco, mas nenhum para as companhias 1 ou 2. Verificar fkCompanhia.'
        WHEN (SELECT COUNT(*) FROM regraAlerta WHERE fkCompanhia IN (1,2)) = 0 THEN
            '⚠️ PROBLEMA: Nenhuma regra de alerta configurada para as companhias 1 ou 2.'
        WHEN (SELECT COUNT(*) FROM alerta WHERE fkCompanhia IN (1,2)) = 0 THEN
            '⚠️ PROBLEMA: Regras existem mas nenhum alerta foi gerado. Verificar query de processamento.'
        ELSE
            '✅ Dados OK: Voos, regras e alertas existem no banco.'
    END AS diagnostico;
