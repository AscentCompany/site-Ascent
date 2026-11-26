-- Teste simples para verificar dados e query de alertas
USE ascent;

-- 1. Verificar estrutura da tabela voo
SELECT 'COLUNAS DA TABELA VOO:' as '';
SHOW COLUMNS FROM voo;

-- 2. Verificar valores de direcao
SELECT 'VALORES DE DIRECAO:' as '';
SELECT DISTINCT direcao FROM aeroportoDirecao;

-- 3. Ver alguns voos (primeiras 3 linhas)
SELECT 'AMOSTRA DE VOOS:' as '';
SELECT * FROM voo LIMIT 3;

-- 4. Contagem geral
SELECT 'TOTAIS:' as '';
SELECT 
    (SELECT COUNT(*) FROM voo) as total_voos,
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'Partida') as total_partidas,
    (SELECT COUNT(*) FROM aeroportoDirecao WHERE direcao = 'Destino') as total_destinos;
