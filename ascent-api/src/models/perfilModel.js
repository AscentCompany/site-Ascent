var database = require("../../database/config");

// Escapa aspas simples para reduzir risco de SQL Injection
function esc(valor) {
    return String(valor).replace(/\\/g, "\\\\").replace(/'/g, "''");
}

// Executa a query e imprime no terminal a instrução SQL + o resultado.
// instrucaoLog é a versão "mascarada" (sem senhas) usada só para o console.
function executarComLog(instrucao, instrucaoLog) {
    console.log("Executando a instrução SQL: \n" + (instrucaoLog || instrucao) + "\n");
    return database.executar(instrucao).then(function (resultado) {
        console.log(resultado);
        return resultado;
    });
}

// Nome e e-mail: leitura
function buscarPorId(idUsuario) {
    var instrucao = `
        SELECT idUsuario, nome, email FROM usuario WHERE idUsuario = ${Number(idUsuario)};
    `;
    return executarComLog(instrucao);
}

// Confere se a senha informada bate com a do banco
function validarSenhaAtual(idUsuario, senhaAtual) {
    var instrucao = `
        SELECT idUsuario FROM usuario WHERE idUsuario = ${Number(idUsuario)} AND senha = '${esc(senhaAtual)}';
    `;
    var instrucaoLog = `
        SELECT idUsuario FROM usuario WHERE idUsuario = ${Number(idUsuario)} AND senha = '********';
    `;
    return executarComLog(instrucao, instrucaoLog);
}

function atualizarNome(idUsuario, nome) {
    var instrucao = `
        UPDATE usuario SET nome = '${esc(nome)}' WHERE idUsuario = ${Number(idUsuario)};
    `;
    return executarComLog(instrucao);
}

function atualizarSenha(idUsuario, novaSenha) {
    var instrucao = `
        UPDATE usuario SET senha = '${esc(novaSenha)}' WHERE idUsuario = ${Number(idUsuario)};
    `;
    var instrucaoLog = `
        UPDATE usuario SET senha = '********' WHERE idUsuario = ${Number(idUsuario)};
    `;
    return executarComLog(instrucao, instrucaoLog);
}

module.exports = {
    buscarPorId,
    validarSenhaAtual,
    atualizarNome,
    atualizarSenha
};