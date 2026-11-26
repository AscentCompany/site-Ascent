-- Criar tabela logsServico (nome correto esperado pelo código Java)
USE ascent;

-- Remover se existir (para garantir limpeza)
DROP TABLE IF EXISTS logsServico;

-- Criar tabela com estrutura baseada nas classes LogServico e LogLeitura
CREATE TABLE logsServico (
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
    INDEX idx_servico (servico),
    INDEX idx_data_hora (dataHora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verificar criação
DESCRIBE logsServico;

SELECT '✓ Tabela logsServico criada com sucesso!' as resultado;
