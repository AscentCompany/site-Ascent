-- =============================================================
-- Script para Criar Tabelas de Alertas
-- =============================================================
-- Este script cria as tabelas regraAlerta e alerta que estão
-- faltando no banco de dados.
-- =============================================================

USE ascent;

-- Tabela: regraAlerta
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

-- Tabela: alerta
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

-- Verificar se as tabelas foram criadas
SELECT 'Tabelas criadas com sucesso!' AS status;

-- Verificar estrutura
DESCRIBE regraAlerta;
DESCRIBE alerta;

-- Verificar se há dados
SELECT COUNT(*) as total_regras FROM regraAlerta;
SELECT COUNT(*) as total_alertas FROM alerta;
