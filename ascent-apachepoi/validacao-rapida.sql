-- Validação rápida da correção
USE ascent;

-- 1. MAIS IMPORTANTE: Verificar valores de direcao
SELECT '1. Valores de direcao (DEVE MOSTRAR: ORIGEM e DESTINO):' as '';
SELECT DISTINCT direcao FROM aeroportoDirecao ORDER BY direcao;

-- 2. Se aparecer ORIGEM e DESTINO, a correção funcionou! ✅
