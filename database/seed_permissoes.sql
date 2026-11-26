-- =============================================================
-- Seed idempotente de Permissoes, Funcionalidades e Vinculos
-- Seguro para rodar em bancos ja existentes (nao duplica dados)
-- =============================================================

-- Permissoes
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
SELECT 'Editar Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Editar Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central Recomendacoes');

-- Funcionalidades
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

-- Vinculo entre Funcionalidades e Permissoes (funcPermissao)
INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Rotas' AND p.nomePermissao = 'Acessar Dashboard Rotas'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Operacoes' AND p.nomePermissao = 'Acessar Dashboard Operacoes'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Configurar Regras Alertas' AND p.nomePermissao = 'Gerenciar Alertas Operacionais'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Gerenciar Funcionarios e Cargos' AND p.nomePermissao = 'Gerenciar Organizacao'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Editar Informacoes Usuario' AND p.nomePermissao = 'Editar Usuario'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Central Recomendacoes' AND p.nomePermissao = 'Acessar Central Recomendacoes'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

-- Garante que todo cargo 'Administrador' de qualquer companhia tenha todas as permissoes
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Administrador'
  AND cp.fkCargo IS NULL;
