-- Criar tabela logleitura para o sistema de importação
USE ascent;

-- Remover se existir (para garantir limpeza)
DROP TABLE IF EXISTS logleitura;

-- Criar tabela com estrutura baseada nas classes LogServico e LogLeitura
CREATE TABLE logleitura (
    idLogServico INT AUTO_INCREMENT PRIMARY KEY,
    categoria VARCHAR(50) NOT NULL,
    servico VARCHAR(100) NOT NULL,
    mensagem TEXT,
    dataHora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    origemCadastro VARCHAR(100),
    fkUsuario INT,
    nomeArquivo VARCHAR(255),
    statusLeitura VARCHAR(50),
    linhasEncontradas INT,
    linhasLidas INT,
    linhasRejeitadas INT,
    detalheErro TEXT,
    idInicialVoo BIGINT,
    INDEX idx_nome_arquivo (nomeArquivo),
    INDEX idx_status (statusLeitura),
    INDEX idx_data_hora (dataHora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verificar criação
DESCRIBE logleitura;

SELECT '✓ Tabela logleitura criada com sucesso!' as resultado;
