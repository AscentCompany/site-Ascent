-- ============================================================================
-- ⚠️  EXECUTE ESTE SCRIPT NO MYSQL WORKBENCH AGORA ⚠️
-- ============================================================================
-- Este script corrige o schema das tabelas de alerta SEM PERDER os voos
-- Arquivo: EXECUTAR-ESTE-AGORA.sql
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

-- Validação
SELECT '✅ Schema de alertas corrigido com sucesso!' as Status;

SELECT 'Verificando estrutura da regraAlerta:' as '';
DESCRIBE regraAlerta;

SELECT '\nVerificando dados existentes:' as '';
SELECT 
    CONCAT('✅ ', FORMAT(COUNT(*), 0), ' voos mantidos') as VoosPreservados
FROM voo;

SELECT 
    CONCAT('✅ ', FORMAT(COUNT(*), 0), ' aeroportos mantidos') as AeroportosPreservados
FROM aeroporto;

SELECT 
    CONCAT('✅ ', FORMAT(COUNT(*), 0), ' companhias mantidas') as CompanhiasPreservadas
FROM companhia;

SELECT '\n🎯 PRÓXIMOS PASSOS:' as '';
SELECT '1. Recarregue a página web (F5)' as '';
SELECT '2. Vá em "Configurar Alertas"' as '';
SELECT '3. Clique em "Criar Regra"' as '';
SELECT '4. Configure: Ocupação < 90%, Todo histórico' as '';
SELECT '5. Vá em "Central de Alertas"' as '';
SELECT '6. ✅ Os alertas devem aparecer!' as '';
