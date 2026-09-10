CREATE DATABASE ascent;

USE ascent;

CREATE TABLE companhia (
    idCompanhia INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    codCompanhia INT,
    nomeCompanhia VARCHAR(45),
    paisCompanhia VARCHAR(45)
);

CREATE TABLE cargo (
    idCargo INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    cargo VARCHAR(45)
);

CREATE TABLE usuario (
    idUsuario INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    cpf CHAR(14),
    email VARCHAR(45),
    senha VARCHAR(45),
    fkCompanhia INT,
    fkCargo INT,
    CONSTRAINT fk_Companhia FOREIGN KEY (fkCompanhia) REFERENCES companhia (idCompanhia),
    CONSTRAINT fk_Cargo FOREIGN KEY (fkCargo) REFERENCES cargo (idCargo)
);

CREATE TABLE aviao (
    idAviao INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    modelo VARCHAR(45),
    numAssentos INT
);

CREATE TABLE voo (
    idVoo INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numVoo INT,
    combustivelGasto FLOAT,
    numPassageiros INT,
    fkCompanhia INT NOT NULL,
    fkAviao INT NOT NULL,
    CONSTRAINT fk_Companhia1 FOREIGN KEY (fkCompanhia) REFERENCES companhia (idCompanhia),
    CONSTRAINT fk_Aviao FOREIGN KEY (fkAviao) REFERENCES aviao (idAviao)
);

CREATE TABLE aeroporto (
    idAeroporto INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    nomeAeroporto VARCHAR(45),
    municipio VARCHAR(45),
    uf VARCHAR(2),
    regiao VARCHAR(45),
    pais VARCHAR(45)
);

CREATE TABLE IF NOT EXISTS aeroportoVoo (
    fkAeroporto INT NOT NULL,
    fkVoo INT NOT NULL,
    direcao VARCHAR(45),
    dia DATE,
    hora TIME,
    PRIMARY KEY (fkAeroporto, fkVoo),
    CONSTRAINT fk_Aeroporto FOREIGN KEY (fkAeroporto) REFERENCES aeroporto (idAeroporto),
    CONSTRAINT fk_Voo FOREIGN KEY (fkVoo) REFERENCES voo (idVoo)
);
