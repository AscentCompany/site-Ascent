var database = require("../../database/config");

function registrarLog(categoria, servico, mensagem, origemCadastro, fkUsuario) {
    const fkUsuarioVal = fkUsuario != null ? Number(fkUsuario) : null;
    const instrucaoSql = `
        INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario)
        VALUES (?, ?, ?, NOW(), ?, ?);
    `;

    console.log("Executando a instrução parametrizada de Log.");
    return database.executar(
        instrucaoSql,
        [categoria, servico, mensagem, origemCadastro, fkUsuarioVal]
    );
}

module.exports = {
    registrarLog
};
