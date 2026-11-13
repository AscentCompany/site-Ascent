var database = require("../../database/config");

function registrarLog(categoria, servico, mensagem, origemCadastro, fkUsuario) {
    let fkUsuarioVal = fkUsuario ? Number(fkUsuario) : "NULL";

    let instrucaoSql = `
        INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario)
        VALUES ('${categoria}', '${servico}', '${mensagemTratada}', NOW(), '${origemCadastro}', ${fkUsuarioVal});
    `;

    console.log("Executando a instrução SQL de Log: \n" + instrucaoSql);
    return database.executar(instrucaoSql);
}

module.exports = {
    registrarLog
};
