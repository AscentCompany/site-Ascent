-- =============================================
-- Script de criação do banco de dados Ascent
-- Execute com: mysql -u root -p < banco.sql
-- =============================================

CREATE DATABASE IF NOT EXISTS ascent;
USE ascent;

-- Tabela: Cargo
CREATE TABLE IF NOT EXISTS cargo (
    idCargo INT AUTO_INCREMENT PRIMARY KEY,
    cargo   VARCHAR(45) NOT NULL
);

-- Tabela: Permissao
CREATE TABLE IF NOT EXISTS permissao (
    idPermissao   INT AUTO_INCREMENT PRIMARY KEY,
    nomePermissao VARCHAR(45) NOT NULL
);

-- Tabela: CargoPermissao
CREATE TABLE IF NOT EXISTS cargoPermissao (
    idCargoPermissao INT AUTO_INCREMENT PRIMARY KEY,
    fkPermissao      INT NOT NULL,
    fkCargo          INT NOT NULL,
    FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao),
    FOREIGN KEY (fkCargo)     REFERENCES cargo(idCargo)
);

-- Tabela: Funcionalidades
CREATE TABLE IF NOT EXISTS funcionalidades (
    idFuncionalidades  INT AUTO_INCREMENT PRIMARY KEY,
    nomeFuncionalidade VARCHAR(45) NOT NULL,
    fkPermissao        INT NOT NULL,
    FOREIGN KEY (fkPermissao) REFERENCES permissao(idPermissao)
);

-- Tabela: Companhia
CREATE TABLE IF NOT EXISTS companhia (
    idCompanhia   INT AUTO_INCREMENT PRIMARY KEY,
    codCompanhia  INT          NOT NULL,
    nomeCompanhia VARCHAR(45)  NOT NULL,
    paisCompanhia VARCHAR(45)  NOT NULL,
    razaoSocial   VARCHAR(100) NOT NULL,
    cnpj          VARCHAR(18)  NOT NULL,
    fkCargo       INT          NOT NULL,
    FOREIGN KEY (fkCargo) REFERENCES cargo(idCargo)
);

-- Tabela: Usuario
CREATE TABLE IF NOT EXISTS usuario (
    idUsuario   INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(45) NOT NULL,
    cpf         CHAR(14)    NOT NULL,
    email       VARCHAR(45) NOT NULL,
    senha       VARCHAR(45) NOT NULL,
    fkCompanhia INT         NOT NULL,
    fkCargo     INT         NOT NULL,
    FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
    FOREIGN KEY (fkCargo)     REFERENCES cargo(idCargo)
);

-- Tabela: LogsServico
CREATE TABLE IF NOT EXISTS logsServico (
    idLog             INT AUTO_INCREMENT PRIMARY KEY,
    categoria         VARCHAR(45)   NOT NULL,
    servico           VARCHAR(50)   NOT NULL,
    mensagem          VARCHAR(255)  NOT NULL,
    dataHora          DATETIME      NOT NULL,
    origemCadastro    VARCHAR(50)   NOT NULL,
    fkUsuario         INT           NULL DEFAULT NULL,
    nomeArquivo       VARCHAR(1024) NULL,
    statusLeitura     VARCHAR(30)   NULL,
    linhasEncontradas INT           NULL,
    linhasLidas       INT           NULL,
    linhasRejeitadas  INT           NULL,
    detalheErro       TEXT          NULL,
    FOREIGN KEY (fkUsuario) REFERENCES usuario(idUsuario),
    CONSTRAINT chk_logsServico_statusLeitura
        CHECK (statusLeitura IS NULL OR statusLeitura IN ('LIDO', 'PARCIALMENTE_LIDO', 'ERRO_NA_LEITURA')),
    CONSTRAINT chk_logsServico_contagensLeitura
        CHECK (
            (linhasEncontradas IS NULL OR linhasEncontradas >= 0)
            AND (linhasLidas IS NULL OR linhasLidas >= 0)
            AND (linhasRejeitadas IS NULL OR linhasRejeitadas >= 0)
        )
);

-- Tabela: Aviao
CREATE TABLE IF NOT EXISTS aviao (
    idAviao     INT AUTO_INCREMENT PRIMARY KEY,
    numAssentos INT         NOT NULL,
    modelo      VARCHAR(45) NOT NULL
);

-- Tabela: Voo
CREATE TABLE IF NOT EXISTS voo (
    idVoo          INT AUTO_INCREMENT PRIMARY KEY,
    numVoo         INT NOT NULL,
    tipoVoo        INT NOT NULL,
    qtdPassageiros INT NOT NULL,
    fkCompanhia    INT NOT NULL,
    fkAviao        INT NOT NULL,
    FOREIGN KEY (fkCompanhia) REFERENCES companhia(idCompanhia),
    FOREIGN KEY (fkAviao)     REFERENCES aviao(idAviao)
);

-- Tabela: Aeroporto
CREATE TABLE IF NOT EXISTS aeroporto (
    idAeroporto   INT AUTO_INCREMENT PRIMARY KEY,
    nomeAeroporto VARCHAR(45) NOT NULL,
    municipio     VARCHAR(45) NOT NULL,
    uf            VARCHAR(2)  NOT NULL,
    regiao        VARCHAR(45) NOT NULL,
    pais          VARCHAR(45) NOT NULL
);

-- Tabela: AeroportoDirecao
CREATE TABLE IF NOT EXISTS aeroportoDirecao (
    fkAeroporto INT         NOT NULL,
    fkVoo       INT         NOT NULL,
    direcao     VARCHAR(45) NOT NULL,
    dia         DATE        NOT NULL,
    hora        TIME        NOT NULL,
    PRIMARY KEY (fkAeroporto, fkVoo),
    FOREIGN KEY (fkAeroporto) REFERENCES aeroporto(idAeroporto),
    FOREIGN KEY (fkVoo)       REFERENCES voo(idVoo)
);

-- Dados iniciais: cargo padrão para não bloquear inserções
INSERT INTO cargo (cargo) VALUES ('Padrão');

SELECT 'Banco criado com sucesso!' AS status;
