-- =============================================================
-- atualizar_aws.sql - Atualizacao segura e idempotente do banco
-- Compativel com MySQL 8.0 na AWS (Linux / Docker)
-- Pode rodar com o sistema no ar, sem derrubar nada.
-- =============================================================
USE ascent;
SET NAMES utf8mb4;

-- 1. Garante coluna idInicialVoo em logsServico
SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'logsServico'
    AND COLUMN_NAME = 'idInicialVoo'
);
SET @sql_add_col := IF(
  @col_exists = 0,
  'ALTER TABLE logsServico ADD COLUMN idInicialVoo BIGINT NULL DEFAULT NULL;',
  'SELECT 1;'
);
PREPARE stmt_col FROM @sql_add_col;
EXECUTE stmt_col;
DEALLOCATE PREPARE stmt_col;

-- 2. Permissoes padrao do sistema
INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard Rotas');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard Operacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard Operacoes');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Alertas Operacionais' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Alertas Operacionais');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Organizacao' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Organizacao');

INSERT INTO permissao (nomePermissao)
SELECT 'Adicionar Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Adicionar Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Editar Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Editar Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Excluir Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Excluir Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Cargos');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central Recomendacoes');

-- 3. Funcionalidades associadas as telas do front-end
INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard Rotas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard Operacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard Operacoes');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configurar Regras Alertas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configurar Regras Alertas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Gerenciar Funcionarios e Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Gerenciar Funcionarios e Cargos');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Editar Informacoes Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Editar Informacoes Usuario');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Central Recomendacoes');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Acessar Dashboard' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Acessar Dashboard');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Exportar Relatorios' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Exportar Relatorios');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Graficos de Ocupacao' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Graficos de Ocupacao');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configuracoes Avancadas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configuracoes Avancadas');

-- 4. Vinculo entre Funcionalidades e Permissoes (funcPermissao)
INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard Rotas'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Rotas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard Operacoes'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Operacoes'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Alertas Operacionais'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Configurar Regras Alertas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Organizacao'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Gerenciar Funcionarios e Cargos'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Editar Usuario'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Editar Informacoes Usuario'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Central Recomendacoes'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Central Recomendacoes'
  AND fp.fkFuncionalidade IS NULL;

-- 5. Garante que toda companhia tenha um cargo 'Administrador'
INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Administrador', co.idCompanhia
FROM companhia co
WHERE NOT EXISTS (
  SELECT 1 FROM cargo c WHERE c.fkCompanhia = co.idCompanhia AND c.cargo = 'Administrador'
);

-- 6. Vincula TODAS as permissoes a TODOS os cargos 'Administrador'
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Administrador'
  AND cp.fkCargo IS NULL;

-- Garante a permissao 'Editar Usuario' (funcionalidade de Perfil) para todos os cargos exceto 'Padrao'
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao = 'Editar Usuario'
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo NOT LIKE 'Padra%'
  AND cp.fkCargo IS NULL;

-- Permissoes operacionais padrao para Gestor de Operacoes Aereas
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao IN ('Acessar Dashboard Operacoes', 'Gerenciar Alertas Operacionais')
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Gestor de Operacoes Aereas'
  AND cp.fkCargo IS NULL;

-- Permissoes analiticas padrao para Analista de Planejamento de Rotas
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao IN ('Acessar Dashboard Rotas', 'Acessar Central Recomendacoes')
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Analista de Planejamento de Rotas'
  AND cp.fkCargo IS NULL;

-- 7. Se alguma companhia nao tem nenhum usuario com cargo Administrador,
--    promove o primeiro usuario cadastrado para Administrador
UPDATE usuario u
JOIN (
  SELECT u2.fkCompanhia, MIN(u2.idUsuario) AS primeiroId
  FROM usuario u2
  GROUP BY u2.fkCompanhia
) primeiro ON primeiro.primeiroId = u.idUsuario
JOIN cargo c_admin ON c_admin.fkCompanhia = u.fkCompanhia AND c_admin.cargo = 'Administrador'
LEFT JOIN (
  SELECT DISTINCT u3.fkCompanhia
  FROM usuario u3
  JOIN cargo c3 ON c3.idCargo = u3.fkCargo
  WHERE c3.cargo = 'Administrador'
) ja_tem ON ja_tem.fkCompanhia = u.fkCompanhia
SET u.fkCargo = c_admin.idCargo
WHERE ja_tem.fkCompanhia IS NULL;
