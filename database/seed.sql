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
