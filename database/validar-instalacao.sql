-- ============================================================================
-- Script de Validação da Instalação do Banco de Dados
-- ============================================================================
-- Execute este script após rodar o ascent.sql para verificar se tudo está OK
-- ============================================================================

USE ascent;

SELECT '========================================' as '';
SELECT 'VALIDAÇÃO DO BANCO DE DADOS ASCENT' as '';
SELECT '========================================' as '';

-- 1. Verificar se todas as tabelas principais existem
SELECT '\n1. VERIFICANDO TABELAS...' as '';
SELECT 
    CASE 
        WHEN COUNT(*) = 14 THEN '✅ TODAS as 14 tabelas existem'
        ELSE CONCAT('❌ FALTAM TABELAS! Encontradas: ', COUNT(*), ' de 14')
    END as Status
FROM information_schema.tables 
WHERE table_schema = 'ascent' 
AND table_name IN (
    'aeroporto', 'aviao', 'companhia', 'voo', 'aeroportoDirecao',
    'cargo', 'usuario', 'logsServico', 'permissao', 'funcionalidade',
    'cargoPermissao', 'funcPermissao', 'regraAlerta', 'alerta'
);

-- 2. Verificar estrutura da tabela regraAlerta (problema crítico anterior)
SELECT '\n2. VERIFICANDO ESTRUTURA REGRAALERTA...' as '';
SELECT 
    CASE 
        WHEN COUNT(*) >= 9 THEN '✅ Tabela regraAlerta com colunas corretas'
        ELSE CONCAT('❌ Estrutura INCORRETA! Colunas encontradas: ', COUNT(*))
    END as Status
FROM information_schema.columns 
WHERE table_schema = 'ascent' 
AND table_name = 'regraAlerta'
AND column_name IN (
    'idRegraAlerta', 'faixaOcupacao', 'severidade', 'janelaAnalise',
    'janelaInicio', 'janelaFim', 'ativo', 'fkCompanhia', 'fkUsuarioCriador'
);

-- Mostrar colunas da regraAlerta para conferência visual
SELECT '\n   Colunas da tabela regraAlerta:' as '';
SELECT column_name as Coluna, data_type as Tipo, 
       CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as Nulavel
FROM information_schema.columns 
WHERE table_schema = 'ascent' AND table_name = 'regraAlerta'
ORDER BY ordinal_position;

-- 3. Verificar dados iniciais (seed)
SELECT '\n3. VERIFICANDO DADOS INICIAIS (SEED)...' as '';

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✅ Companhia Ascent Airlines criada (ID: ', idCompanhia, ', Código: ', codCompanhia, ')')
        ELSE '❌ Companhia Ascent Airlines NÃO encontrada'
    END as Status,
    codCompanhia as CodigoCompanhia
FROM companhia 
WHERE codCompanhia = 1001
LIMIT 1;

SELECT 
    CASE 
        WHEN COUNT(*) >= 3 THEN CONCAT('✅ ', COUNT(*), ' cargos criados')
        ELSE CONCAT('❌ Apenas ', COUNT(*), ' cargos encontrados (esperado: 3+)')
    END as Status
FROM cargo 
WHERE fkCompanhia = (SELECT idCompanhia FROM companhia WHERE codCompanhia = 1001);

SELECT 
    CASE 
        WHEN COUNT(*) >= 6 THEN CONCAT('✅ ', COUNT(*), ' usuários de teste criados')
        ELSE CONCAT('❌ Apenas ', COUNT(*), ' usuários encontrados (esperado: 6)')
    END as Status
FROM usuario 
WHERE fkCompanhia = (SELECT idCompanhia FROM companhia WHERE codCompanhia = 1001);

SELECT 
    CASE 
        WHEN COUNT(*) >= 7 THEN CONCAT('✅ ', COUNT(*), ' permissões criadas')
        ELSE CONCAT('❌ Apenas ', COUNT(*), ' permissões encontradas (esperado: 7+)')
    END as Status
FROM permissao;

-- 4. Verificar se há dados importados (opcional)
SELECT '\n4. VERIFICANDO DADOS IMPORTADOS...' as '';

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✅ ', FORMAT(COUNT(*), 0), ' voos importados')
        ELSE 'ℹ️  Nenhum voo importado ainda (execute o importador Java)'
    END as Status
FROM voo;

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✅ ', FORMAT(COUNT(*), 0), ' aeroportos cadastrados')
        ELSE 'ℹ️  Nenhum aeroporto cadastrado ainda'
    END as Status
FROM aeroporto;

-- 5. Testar query de alertas (a que estava falhando antes)
SELECT '\n5. TESTANDO QUERY DE ALERTAS...' as '';

-- Esta query só funciona se houver voos importados
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 
            CONCAT('✅ Query de alertas funcionando! Encontrados ', COUNT(*), ' voos com ocupação < 90%')
        WHEN (SELECT COUNT(*) FROM voo) = 0 THEN
            'ℹ️  Sem voos para testar (importe dados primeiro)'
        ELSE 
            '⚠️  Query executou mas não retornou resultados'
    END as Status
FROM (
    SELECT 
        v.idVoo,
        aOrig.direcao as direcaoOrigem,
        aDest.direcao as direcaoDestino,
        ROUND((v.qtdPassageiros / av.numAssentos) * 100, 2) as ocupacao
    FROM voo v
    JOIN aviao av ON v.fkAviao = av.idAviao
    JOIN aeroportoDirecao aOrig ON aOrig.fkVoo = v.idVoo AND aOrig.direcao = 'ORIGEM'
    JOIN aeroportoDirecao aDest ON aDest.fkVoo = v.idVoo AND aDest.direcao = 'DESTINO'
    WHERE (v.qtdPassageiros / av.numAssentos) * 100 < 90
    LIMIT 10
) as teste;

-- 6. Verificar Foreign Keys críticas
SELECT '\n6. VERIFICANDO FOREIGN KEYS...' as '';
SELECT 
    CASE 
        WHEN COUNT(*) >= 10 THEN CONCAT('✅ ', COUNT(*), ' Foreign Keys configuradas')
        ELSE CONCAT('⚠️  Apenas ', COUNT(*), ' FKs encontradas')
    END as Status
FROM information_schema.table_constraints
WHERE constraint_schema = 'ascent' 
AND constraint_type = 'FOREIGN KEY';

-- Resumo final
SELECT '\n========================================' as '';
SELECT 'RESUMO DA VALIDAÇÃO' as '';
SELECT '========================================' as '';
SELECT 
    CONCAT(
        '\n✅ Se todos os itens acima estão OK, o banco está pronto!\n',
        '📌 Código da companhia: 1001\n',
        '👤 Usuários de teste: camila/camila, gustavo/gustavo\n',
        '🔧 Para importar dados ANAC: execute o importador Java\n',
        '🌐 Para iniciar a API: cd ascent-api && node app.js\n'
    ) as '';
