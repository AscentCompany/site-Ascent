CREATE SCHEMA IF NOT EXISTS ascent;
USE ascent;

CREATE TABLE IF NOT EXISTS aeroporto(
  idAeroporto INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nomeAeroporto VARCHAR(200) NULL DEFAULT NULL,
  municipio VARCHAR(100) NULL DEFAULT NULL,
  uf VARCHAR(2) NULL DEFAULT NULL,
  regiao VARCHAR(100) NULL DEFAULT NULL,
  pais VARCHAR(100) NULL DEFAULT NULL,
  icao VARCHAR(10) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS aviao (
  idAviao INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  modelo VARCHAR(45) NULL DEFAULT NULL,
  numAssentos INT NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS companhia (
  idCompanhia INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  codCompanhia INT NULL DEFAULT NULL,
  nomeCompanhia VARCHAR(200) NULL DEFAULT NULL,
  paisCompanhia VARCHAR(100) NULL DEFAULT NULL,
  razaoSocial VARCHAR(200) NULL DEFAULT NULL,
  cnpj VARCHAR(30) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS voo (
  idVoo INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  numVoo INT NULL DEFAULT NULL,
  tipoVoo INT NULL DEFAULT NULL,
  qtdPassageiros INT NULL DEFAULT NULL,
  fkCompanhia INT NOT NULL,
  CONSTRAINT chkFkCompanhia_voo FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  fkAviao INT NOT NULL,
  CONSTRAINT chkFkAviao_voo FOREIGN KEY (fkAviao) REFERENCES aviao(idAviao)
);

CREATE TABLE IF NOT EXISTS aeroportoDirecao (
  fkAeroporto INT NOT NULL,
  CONSTRAINT chkFkAeroporto_ad FOREIGN KEY (fkAeroporto) REFERENCES aeroporto(idAeroporto),
  fkVoo INT NOT NULL,
  CONSTRAINT chkFkVoo_ad FOREIGN KEY (fkVoo) REFERENCES voo(idVoo),
  direcao VARCHAR(45) NULL DEFAULT NULL,
  dia DATE NULL DEFAULT NULL,
  hora TIME NULL DEFAULT NULL,
  PRIMARY KEY (fkAeroporto, fkVoo)
);

CREATE TABLE IF NOT EXISTS cargo (
  idCargo INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  cargo VARCHAR(45) NULL DEFAULT NULL,
  fkCompanhia INT NOT NULL,
  CONSTRAINT chkFkCompanhia_cargo FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia)
);

CREATE TABLE IF NOT EXISTS usuario (
  idUsuario INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nome VARCHAR(45) NULL DEFAULT NULL,
  cpf CHAR(14) UNIQUE NULL DEFAULT NULL,
  email VARCHAR(45) NULL DEFAULT NULL,
  senha VARCHAR(45) NULL DEFAULT NULL,
  fkCompanhia INT NOT NULL,
  CONSTRAINT chkFkCompanhia_usuario FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  fkCargo INT NOT NULL,
  CONSTRAINT chkFkCargo_usuario FOREIGN KEY (fkCargo) REFERENCES cargo(idCargo)
);

CREATE TABLE IF NOT EXISTS logsServico (
  idLogServico INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  categoria VARCHAR(50) NULL DEFAULT NULL,
  servico VARCHAR(50) NULL DEFAULT NULL,
  mensagem VARCHAR(255) NULL DEFAULT NULL,
  dataHora DATETIME NULL DEFAULT NULL,
  origemCadastro VARCHAR(100) NULL DEFAULT NULL,
  fkUsuario INT NULL DEFAULT NULL,
  CONSTRAINT chkFkUsuario_log FOREIGN KEY (fkUsuario) REFERENCES usuario(idUsuario),
  nomeArquivo VARCHAR(1024) NULL DEFAULT NULL,
  statusLeitura VARCHAR(30) NULL DEFAULT NULL,
  linhasEncontradas INT NULL DEFAULT NULL,
  linhasLidas INT NULL DEFAULT NULL,
  linhasRejeitadas INT NULL DEFAULT NULL,
  detalheErro TEXT NULL DEFAULT NULL,
  idInicialVoo BIGINT NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS permissao (
  idPermissao INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nomePermissao VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS funcionalidade (
  idFuncionalidade INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nomeFuncionalidade VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS cargoPermissao (
  fkPermissao INT NOT NULL,
  CONSTRAINT chkFkPermissao_cp FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao),
  fkCargo INT NOT NULL,
  CONSTRAINT chkFkCargo_cp FOREIGN KEY (fkCargo) REFERENCES cargo(idCargo),
  PRIMARY KEY (fkPermissao, fkCargo)
);

CREATE TABLE IF NOT EXISTS funcPermissao (
  fkFuncionalidade INT NOT NULL,
  CONSTRAINT chkFkFuncionalidade_fp FOREIGN KEY (fkFuncionalidade) REFERENCES funcionalidade(idFuncionalidade),
  fkPermissao INT NOT NULL,
  CONSTRAINT chkFkPermissao_fp FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao),
  PRIMARY KEY (fkFuncionalidade, fkPermissao)
);

CREATE TABLE IF NOT EXISTS regraAlerta (
  idRegraAlerta INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  faixaOcupacao DECIMAL(5,2) NOT NULL,
  severidade VARCHAR(10) NOT NULL,
  janelaAnalise VARCHAR(20) NOT NULL,
  janelaInicio DATE NULL DEFAULT NULL,
  janelaFim DATE NULL DEFAULT NULL,
  ativo TINYINT(1) NOT NULL,
  fkCompanhia INT NOT NULL,
  CONSTRAINT chkFkCompanhia_ra FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  fkUsuarioCriador INT NOT NULL,
  CONSTRAINT chkFkUsuario_ra FOREIGN KEY (fkUsuarioCriador) REFERENCES usuario(idUsuario),
  dataCriacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_regra (faixaOcupacao, janelaAnalise, janelaInicio, janelaFim, fkCompanhia)
);

CREATE TABLE IF NOT EXISTS alerta (
  idAlerta INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  origemIata VARCHAR(10) NOT NULL,
  destinoIata VARCHAR(10) NOT NULL,
  ocupacaoMedia DECIMAL(5,2) NOT NULL,
  severidade VARCHAR(10) NOT NULL,
  lida TINYINT(1) NOT NULL,
  fkRegraAlerta INT NOT NULL,
  CONSTRAINT chkFkRegra_alerta FOREIGN KEY (fkRegraAlerta) REFERENCES regraAlerta(idRegraAlerta),
  fkCompanhia INT NOT NULL,
  CONSTRAINT chkFkCompanhia_alerta FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  dataCriacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- Dados Iniciais (Seed Idempotente)
-- =============================================================

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

INSERT INTO permissao (nomePermissao)
SELECT 'Excluir Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Excluir Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Cargos');

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
