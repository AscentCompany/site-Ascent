package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

/**
 * Controla o estado de importação de cada arquivo usando objetos LogLeitura.
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


    public boolean jaFoiImportado(String nomeArquivo) {
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT 1 FROM logsServico " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' " +
                "AND statusLeitura IN (?, ?) LIMIT 1",
                Integer.class, nomeArquivo, StatusLeitura.LIDO.name(), StatusLeitura.PARCIALMENTE_LIDO.name());
        return !resultado.isEmpty();
    }


    public Long buscarIdInicialPendente(String nomeArquivo) {
        List<Long> resultado = jdbcTemplate.queryForList(
                "SELECT idInicialVoo FROM logsServico " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' " +
                "AND statusLeitura = ? " +
                "ORDER BY idLogServico DESC LIMIT 1",
                Long.class, nomeArquivo, StatusLeitura.EM_ANDAMENTO.name());
        return resultado.isEmpty() ? null : resultado.get(0);
    }


    public void iniciarArquivo(LogLeitura log) {
        int atualizados = jdbcTemplate.update(
                "UPDATE logsServico SET categoria = ?, mensagem = ?, dataHora = ?, origemCadastro = ?, idInicialVoo = ? " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = ?",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getOrigemCadastro(), log.getIdInicialVoo(),
                log.getNomeArquivo(), StatusLeitura.EM_ANDAMENTO.name());
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getOrigemCadastro(), log.getIdInicialVoo(),
                log.getNomeArquivo());

        if (atualizados == 0) {
            jdbcTemplate.update(
                    "INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario," +
                    " nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro, idInicialVoo)" +
                    " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    log.getCategoria(), log.getServico(), log.getMensagem(), log.getDataHora(), log.getOrigemCadastro(), log.getFkUsuario(),
                    log.getNomeArquivo(), log.getStatusLeitura().name(), log.getLinhasEncontradas(), log.getLinhasLidas(),
                    log.getNomeArquivo(), log.getStatusLeitura(), log.getLinhasEncontradas(), log.getLinhasLidas(),
                    log.getLinhasRejeitadas(), log.getDetalheErro(), log.getIdInicialVoo());
        }
    }

    public void concluirArquivo(LogLeitura log) {
        jdbcTemplate.update(
                "UPDATE logsServico SET categoria = ?, mensagem = ?, dataHora = ?, origemCadastro = ?," +
                " statusLeitura = ?, linhasEncontradas = ?, linhasLidas = ?, linhasRejeitadas = ?, detalheErro = ?" +
                " WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = ?",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getOrigemCadastro(),
                log.getStatusLeitura().name(), log.getLinhasEncontradas(), log.getLinhasLidas(), log.getLinhasRejeitadas(), log.getDetalheErro(),
                log.getNomeArquivo(), StatusLeitura.EM_ANDAMENTO.name());
                " WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getOrigemCadastro(),
                log.getStatusLeitura(), log.getLinhasEncontradas(), log.getLinhasLidas(), log.getLinhasRejeitadas(), log.getDetalheErro(),
                log.getNomeArquivo());
    }

 
    public void marcarErro(LogLeitura log) {
        jdbcTemplate.update(
                "UPDATE logsServico SET categoria = ?, mensagem = ?, dataHora = ?, detalheErro = ? " +
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = ?",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getDetalheErro(),
                log.getNomeArquivo(), StatusLeitura.EM_ANDAMENTO.name());
                "WHERE nomeArquivo = ? AND servico = 'importacao' AND statusLeitura = 'EM_ANDAMENTO'",
                log.getCategoria(), log.getMensagem(), log.getDataHora(), log.getDetalheErro(),
                log.getNomeArquivo());
    }
}
