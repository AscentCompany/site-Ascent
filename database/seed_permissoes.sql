-- =============================================================
-- Seed idempotente de Permissões, Funcionalidades e Vínculos
-- Seguro para rodar em bancos já existentes (não duplica dados)
-- =============================================================

-- Permissões
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
SELECT 'Editar Usuário' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Editar Usuário');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Central de Recomendações' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central de Recomendações');

-- Funcionalidades
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

-- Vínculo entre Funcionalidades e Permissões (funcPermissao)
INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard de Rotas' AND p.nomePermissao = 'Acessar Dashboard de Rotas'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard de Operações' AND p.nomePermissao = 'Acessar Dashboard de Operações'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Configurar Regras de Alertas' AND p.nomePermissao = 'Gerenciar Alertas Operacionais'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Gerenciar Funcionários e Cargos' AND p.nomePermissao = 'Gerenciar Organização'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Editar Informações de Usuário' AND p.nomePermissao = 'Editar Usuário'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f, permissao p
WHERE f.nomeFuncionalidade = 'Visualizar Central de Recomendações' AND p.nomePermissao = 'Acessar Central de Recomendações'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

-- Garante que todo cargo 'Administrador' de qualquer companhia tenha todas as permissões
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Administrador'
  AND cp.fkCargo IS NULL;
