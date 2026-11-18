package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Controla o estado de importação de cada arquivo.
 *
 * Estados possíveis em logsServico.statusLeitura (servico='importacao'):
 *   EM_ANDAMENTO       -> o arquivo começou a ser importado e ainda não terminou
 *   LIDO               -> terminou sem nenhuma linha rejeitada
 *   PARCIALMENTE_LIDO  -> terminou, mas algumas linhas foram rejeitadas pela validação
 *
 * LIDO e PARCIALMENTE_LIDO já gravaram dados no banco e por isso NÃO devem ser
 * reprocessados. Apenas EM_ANDAMENTO é retomado (com limpeza dos dados parciais).
 */
public class LogImportacaoDao {

    private final JdbcTemplate jdbcTemplate;

    public LogImportacaoDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        garantirColunaIdInicial();
    }

    /**
     * Cria a coluna idInicialVoo em bancos que foram criados antes desta versão.
     * É idempotente: só executa o ALTER quando a coluna realmente não existe.
     */
    private void garantirColunaIdInicial() {
        Integer existe = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.COLUMNS " +
                "WHERE TABLE_SCHEMA = DATABASE() " +
                "AND TABLE_NAME = 'logsServico' AND COLUMN_NAME = 'idInicialVoo'",
                Integer.class);
        if (existe == null || existe == 0) {
            jdbcTemplate.execute(
                    "ALTER TABLE logsServico ADD COLUMN idInicialVoo BIGINT NULL DEFAULT NULL");
        }
    }

    /**
     * O arquivo já gravou seus dados? Só considera não importado quando o estado
     * é EM_ANDAMENTO (ou quando não existe nenhum registro).
     */
    public boolean jaFoiImportado(String nomeArquivo) {
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT 1 FROM logsServico " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' " +
                "AND statusLeitura IN ('LIDO', 'PARCIALMENTE_LIDO') LIMIT 1",
                Integer.class, nomeArquivo);
        return !resultado.isEmpty();
    }

    /**
     * Retorna o idInicialVoo de uma importação interrompida, ou null se o arquivo
     * nunca começou. Esse id delimita exatamente os voos que precisam ser apagados
     * antes de reprocessar o arquivo.
     */
    public Long buscarIdInicialPendente(String nomeArquivo) {
        List<Long> resultado = jdbcTemplate.queryForList(
                "SELECT idInicialVoo FROM logsServico " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' " +
                "AND statusLeitura = 'EM_ANDAMENTO' " +
                "ORDER BY idLogServico DESC LIMIT 1",
                Long.class, nomeArquivo);
        return resultado.isEmpty() ? null : resultado.get(0);
    }

    /**
     * Marca o arquivo como EM_ANDAMENTO antes da primeira linha ser gravada.
     * Se já existir um EM_ANDAMENTO (retomada), reaproveita a linha em vez de
     * acumular registros órfãos.
     */
    public void iniciarArquivo(String nomeArquivo, long idInicialVoo) {
        int atualizados = jdbcTemplate.update(
                "UPDATE logsServico SET dataHora = ?, idInicialVoo = ?, mensagem = ? " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                LocalDateTime.now(), idInicialVoo,
                "Importação em andamento.", nomeArquivo);

        if (atualizados == 0) {
            jdbcTemplate.update(
                    "INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro," +
                    " nomeArquivo, statusLeitura, idInicialVoo) VALUES (?,?,?,?,?,?,?,?)",
                    "INFO", "importacao", "Importação em andamento.", LocalDateTime.now(), "Java",
                    nomeArquivo, "EM_ANDAMENTO", idInicialVoo);
        }
    }

    /**
     * Fecha o arquivo com o resultado final. Atualiza todas as linhas EM_ANDAMENTO
     * daquele arquivo, então não sobra estado pendente para a próxima execução.
     * Qualquer falha aqui é propagada: se não for possível registrar o resultado,
     * o job termina com erro em vez de deixar dados gravados sem controle.
     */
    public void concluirArquivo(String nomeArquivo, LeitorExcel.ResultadoLeitura resultado) {
        String categoria = switch (resultado.getStatusLeitura()) {
            case "LIDO"              -> "INFO";
            case "PARCIALMENTE_LIDO" -> "WARN";
            default                  -> "ERROR";
        };
        String mensagem = String.format("Leitura %s: %d encontradas, %d lidas, %d rejeitadas.",
                resultado.getStatusLeitura(),
                resultado.getLinhasEncontradas(),
                resultado.getLinhasLidas(),
                resultado.getLinhasRejeitadas());

        jdbcTemplate.update(
                "UPDATE logsServico SET categoria = ?, mensagem = ?, dataHora = ?, origemCadastro = ?," +
                " statusLeitura = ?, linhasEncontradas = ?, linhasLidas = ?, linhasRejeitadas = ?, detalheErro = ?" +
                " WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                categoria, mensagem, LocalDateTime.now(), "Java",
                resultado.getStatusLeitura(),
                resultado.getLinhasEncontradas(),
                resultado.getLinhasLidas(),
                resultado.getLinhasRejeitadas(),
                resultado.getDetalheErro(),
                nomeArquivo);
    }

    /**
     * Registra a falha mantendo o estado EM_ANDAMENTO, para que a próxima execução
     * saiba que existem dados parciais daquele arquivo e os remova antes de retomar.
     */
    public void marcarErro(String nomeArquivo, String detalhe) {
        jdbcTemplate.update(
                "UPDATE logsServico SET categoria = 'ERROR', mensagem = ?, dataHora = ?, detalheErro = ? " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                "Importação interrompida; será retomada na próxima execução.",
                LocalDateTime.now(), detalhe, nomeArquivo);
    }
}
