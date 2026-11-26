-- =============================================================
-- atualizar_aws.sql — Atualização segura e idempotente do banco
-- Compatível com MySQL 8.0 na AWS (Linux / Docker)
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

-- 2. Permissões padrão do sistema
INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard de Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard de Rotas');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard de Operações' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard de Operações');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Alertas Operacionais' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Alertas Operacionais');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Organização' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Organização');

INSERT INTO permissao (nomePermissao)
SELECT 'Adicionar Usuário' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Adicionar Usuário');

INSERT INTO permissao (nomePermissao)
SELECT 'Editar Usuário' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Editar Usuário');

INSERT INTO permissao (nomePermissao)
SELECT 'Excluir Usuário' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Excluir Usuário');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Cargos');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Central de Recomendações' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central de Recomendações');

-- 3. Funcionalidades associadas às telas do front-end
INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard de Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard de Rotas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard de Operações' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard de Operações');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configurar Regras de Alertas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configurar Regras de Alertas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Gerenciar Funcionários e Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Gerenciar Funcionários e Cargos');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Editar Informações de Usuário' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Editar Informações de Usuário');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Central de Recomendações' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Central de Recomendações');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Acessar Dashboard' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Acessar Dashboard');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Exportar Relatórios' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Exportar Relatórios');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Gráficos de Ocupação' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Gráficos de Ocupação');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configurações Avançadas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configurações Avançadas');

-- 4. Vínculo entre Funcionalidades e Permissões (funcPermissao)
INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard de Rotas'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard de Rotas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard de Operações'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard de Operações'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Alertas Operacionais'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Configurar Regras de Alertas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Organização'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Gerenciar Funcionários e Cargos'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Editar Usuário'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Editar Informações de Usuário'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Central de Recomendações'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Central de Recomendações'
  AND fp.fkFuncionalidade IS NULL;

-- 5. Garante que toda companhia tenha um cargo 'Administrador'
INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Administrador', co.idCompanhia
FROM companhia co
WHERE NOT EXISTS (
  SELECT 1 FROM cargo c WHERE c.fkCompanhia = co.idCompanhia AND c.cargo = 'Administrador'
);

-- 6. Vincula TODAS as permissões a TODOS os cargos 'Administrador'
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Administrador'
  AND cp.fkCargo IS NULL;

-- 7. Se alguma companhia não tem nenhum usuário com cargo Administrador,
--    promove o primeiro usuário cadastrado para Administrador
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
