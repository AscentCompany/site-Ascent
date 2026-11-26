-- Dados iniciais (idempotente). Rode via: ./inserir-dados.sh
USE ascent;

INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj)
SELECT 1001, 'Ascent Airlines', 'Brasil', 'Ascent Linhas Aereas S.A.', '12.345.678/0001-99'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM companhia WHERE codCompanhia = 1001);

INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Administrador', c.idCompanhia
FROM companhia c
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (
    SELECT 1 FROM cargo g WHERE g.cargo = 'Administrador' AND g.fkCompanhia = c.idCompanhia
  );

INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Gestor de Operacoes Aereas', c.idCompanhia
FROM companhia c
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (
    SELECT 1 FROM cargo g WHERE g.cargo = 'Gestor de Operacoes Aereas' AND g.fkCompanhia = c.idCompanhia
  );

INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Analista de Planejamento de Rotas', c.idCompanhia
FROM companhia c
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (
    SELECT 1 FROM cargo g WHERE g.cargo = 'Analista de Planejamento de Rotas' AND g.fkCompanhia = c.idCompanhia
  );

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Camila', '111.222.333-44', 'camila@ascent.com', 'camila', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Administrador'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.222.333-44');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Givoanna', '111.222.333-55', 'giovanna@ascent.com', 'giovanna', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Administrador'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.222.333-55');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Gustavo', '111.333.444-77', 'gustavo@ascent.com', 'gustavo', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Gestor de Operacoes Aereas'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.333.444-77');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Lucas', '111.222.333-88', 'lucas@ascent.com', 'lucas', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Gestor de Operacoes Aereas'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.222.333-88');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Matheus', '111.222.333-99', 'matheus@ascent.com', 'matheus', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Analista de Planejamento de Rotas'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.222.333-99');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Thamyres', '111.222.333-00', 'thamyres@ascent.com', 'thamyres', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Analista de Planejamento de Rotas'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.222.333-00');

-- Permissoes padrao do sistema
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
SELECT 'Acessar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central Recomendacoes');

-- Funcionalidades associadas aos modulos
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

-- Vinculo inicial entre Funcionalidades e Permissoes (funcPermissao)
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
WHERE f.nomeFuncionalidade = 'Visualizar Central Recomendacoes'
  AND p.nomePermissao = 'Acessar Central Recomendacoes'
  AND NOT EXISTS (SELECT 1 FROM funcPermissao WHERE fkFuncionalidade = f.idFuncionalidade AND fkPermissao = p.idPermissao);

INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN companhia co ON co.idCompanhia = c.fkCompanhia
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE co.codCompanhia = 1001
  AND c.cargo = 'Administrador'
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
