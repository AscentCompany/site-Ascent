-- ============================================================================
-- Script para Corrigir Schema das Tabelas de Alerta
-- ============================================================================
-- Este script atualiza as tabelas de alerta para o schema correto do ascent.sql
-- SEM PERDER os dados de voos, aeroportos, aviões e companhias já importados
-- ============================================================================

USE ascent;

-- Remover tabelas antigas de alerta (se existirem)
DROP TABLE IF EXISTS alerta;
DROP TABLE IF EXISTS regraAlerta;
DROP TABLE IF EXISTS alertaParametrizado;
DROP TABLE IF EXISTS alertaFaixaOcupacao;

-- Recriar tabela regraAlerta com schema correto
CREATE TABLE regraAlerta (
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

-- Recriar tabela alerta com schema correto
CREATE TABLE alerta (
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

SELECT 'Schema de alertas corrigido com sucesso!' as Status;
SELECT 'Tabelas recriadas: regraAlerta, alerta' as Mensagem;
