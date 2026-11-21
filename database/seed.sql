-- Dados iniciais (idempotente). Rode via: ./inserir-dados.sh
USE ascent;

INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj)
SELECT 1001, 'Ascent Airlines', 'Brasil', 'Ascent Linhas Aéreas S.A.', '12.345.678/0001-99'
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
SELECT 'Gestor de Operações Aereas', c.idCompanhia
FROM companhia c
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (
    SELECT 1 FROM cargo g WHERE g.cargo = 'Gestor de Operações Aereas' AND g.fkCompanhia = c.idCompanhia
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
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Gestor de Operações Aereas'
WHERE c.codCompanhia = 1001
  AND NOT EXISTS (SELECT 1 FROM usuario u WHERE u.cpf = '111.333.444-77');

INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo)
SELECT 'Lucas', '111.222.333-88', 'lucas@ascent.com', 'lucas', c.idCompanhia, g.idCargo
FROM companhia c
JOIN cargo g ON g.fkCompanhia = c.idCompanhia AND g.cargo = 'Gestor de Operações Aereas'
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

-- Permissões padrão do sistema
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

-- Funcionalidades associadas aos módulos
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

-- Vínculo inicial entre Funcionalidades e Permissões (funcPermissao)
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
