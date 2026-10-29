CREATE SCHEMA IF NOT EXISTS ascent;
USE ascent;

CREATE TABLE IF NOT EXISTS aeroporto(
  idAeroporto INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nomeAeroporto VARCHAR(200) NULL DEFAULT NULL,
  municipio VARCHAR(100) NULL DEFAULT NULL,
  uf VARCHAR(2) NULL DEFAULT NULL,
  regiao VARCHAR(100) NULL DEFAULT NULL,
  pais VARCHAR(100) NULL DEFAULT NULL
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
  detalheErro TEXT NULL DEFAULT NULL
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

INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj) VALUES 
(1001, 'Ascent Airlines', 'Brasil', 'Ascent Linhas Aéreas S.A.', '12.345.678/0001-99');


INSERT INTO cargo (cargo, fkCompanhia) VALUES 
('Administrador', 1),
('Gestor de Operações Aereas', 1),
('Analista de Planejamento de Rotas', 1);


INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo) VALUES 
('Camila', '111.222.333-44', 'camila@ascent.com', 'camila', 1, 1),
('Givoanna', '111.222.333-55', 'giovanna@ascent.com', 'giovanna', 1, 1),
('Gustavo', '111.333.444-77', 'gustavo@ascent.com', 'gustavo', 1, 2),
('Lucas', '111.222.333-88', 'lucas@ascent.com', 'lucas', 1, 2),
('Matheus', '111.222.333-99', 'matheus@ascent.com', 'matheus', 1, 3),
('Thamyres', '111.222.333-00', 'thamyres@ascent.com', 'thamyres', 1, 3);

INSERT INTO permissao (nomePermissao) VALUES 
('Adicionar Usuário'),
('Editar Usuário'),
('Excluir Usuário'),
('Gerenciar Cargos');

INSERT INTO funcionalidade (nomeFuncionalidade) VALUES 
('Acessar Dashboard'),
('Exportar Relatórios'),
('Visualizar Gráficos de Ocupação'),
('Configurações Avançadas');