CREATE DATABASE IF NOT EXISTS ascent;
USE ascent;

CREATE TABLE IF NOT EXISTS aeroporto(
  idAeroporto INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nomeAeroporto VARCHAR(45) NOT NULL,
  municipio VARCHAR(45) NULL DEFAULT NULL,
  uf VARCHAR(2) NULL DEFAULT NULL,
  regiao VARCHAR(45) NULL DEFAULT NULL,
  pais VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS aviao(
  idAviao INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  modelo VARCHAR(45) NOT NULL,
  numAssentos INT NULL DEFAULT NULL
);
  
CREATE TABLE IF NOT EXISTS empresa(
  idEmpresa INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  codCompanhia VARCHAR(25) DEFAULT NULL,
  nomeCompanhia VARCHAR(45) NOT NULL,
  paisCompanhia VARCHAR(45) DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS voo(
  idVoo INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  numVoo INT NOT NULL,
  combustivelGasto FLOAT NULL DEFAULT NULL,
  numPassageiros INT NULL DEFAULT NULL,
  fkEmpresa INT NOT NULL,
  CONSTRAINT chkFkCompanhia FOREIGN KEY (fkEmpresa) REFERENCES empresa(idEmpresa),
  fkAviao INT NOT NULL,
  CONSTRAINT chkFkAviao FOREIGN KEY (fkAviao) REFERENCES aviao(idAviao)
);


CREATE TABLE IF NOT EXISTS aeroportoVoo(
  idAeroportoVoo INT NOT NULL AUTO_INCREMENT,
  fkAeroporto INT NOT NULL,
  CONSTRAINT chkFkAeroporto FOREIGN KEY (fkAeroporto) REFERENCES aeroporto(idAeroporto),
  fkVoo INT NOT NULL,
  CONSTRAINT chkFkVoo FOREIGN KEY (fkVoo) REFERENCES voo(idVoo),
  direcao VARCHAR(45) NULL DEFAULT NULL,
  dia DATE NULL DEFAULT NULL,
  hora TIME NULL DEFAULT NULL,
  PRIMARY KEY(idAeroportoVoo, fkAeroporto, fkVoo)
);

CREATE TABLE IF NOT EXISTS companhia(
  idCompanhia INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  razaoSocial VARCHAR(100) NOT NULL,
  cnpj VARCHAR(18) NOT NULL,
  dataInicio DATE NOT NULL,
  dataFim DATE NULL DEFAULT NULL,
  fkEmpresa INT NULL DEFAULT NULL,
  CONSTRAINT chkFkEmpresa FOREIGN KEY (fkEmpresa) REFERENCES empresa(idEmpresa)
);

CREATE TABLE IF NOT EXISTS cargo(
  idCargo INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  fkCompanhia INT NULL DEFAULT NULL,
  CONSTRAINT chkFkCompanhia_cargo FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  cargo VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS permissao(
  idPermissao INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nome VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS cargoPermissao(
  idCargoPermissao INT NOT NULL AUTO_INCREMENT,
  fkPermissao INT NOT NULL,
  CONSTRAINT chkFkPermissao_cp FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao),
  fkCargo INT NOT NULL,
  CONSTRAINT chkFkCargo_cp FOREIGN KEY (fkCargo) REFERENCES cargo(idCargo),
  PRIMARY KEY(idCargoPermissao, fkPermissao, fkCargo)
);

CREATE TABLE IF NOT EXISTS funcionalidade(
  idFuncionalidade INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nome VARCHAR(45) NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS permissaoFuncionalidade(
  idpermissaoFuncionalidade INT NOT NULL AUTO_INCREMENT,
  fkPermissao INT NOT NULL,
  CONSTRAINT chkFkPermissao FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao),
  fkFuncionalidade INT NOT NULL,
  CONSTRAINT chkFkFuncionalidade FOREIGN KEY (fkFuncionalidade) REFERENCES funcionalidade(idFuncionalidade),
  PRIMARY KEY(idpermissaoFuncionalidade, fkPermissao, fkFuncionalidade)
);

CREATE TABLE IF NOT EXISTS usuario(
  idUsuario INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  nome VARCHAR(45) NOT NULL,
  email VARCHAR(45) NOT NULL,
  senha VARCHAR(45) NOT NULL,
  fkCompanhia INT NOT NULL DEFAULT 1,
  CONSTRAINT chkFkCompanhia_usuario FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
  fkCargo INT NOT NULL,
  CONSTRAINT chkFkCargo_usuario FOREIGN KEY (fkCargo) REFERENCES cargo(idCargo)
);

CREATE TABLE IF NOT EXISTS logServico(
  idLogServico INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  categoria VARCHAR(50) NULL DEFAULT NULL,
  servico VARCHAR(50) NULL DEFAULT NULL,
  mensagem VARCHAR(100) NULL DEFAULT NULL,
  dataHora DATETIME NULL DEFAULT NULL,
  origemCadastro VARCHAR(50) NULL DEFAULT NULL,
  fkUsuario INT NULL DEFAULT NULL,
  CONSTRAINT chkFkUsuario FOREIGN KEY (fkUsuario) REFERENCES usuario(idUsuario)
);