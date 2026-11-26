var database = require("../../database/config");

// Escapa aspas simples para reduzir risco de SQL Injection
// (o executar() do Web Data Viz recebe apenas a string da query)
function esc(valor) {
    return String(valor).replace(/\\/g, "\\\\").replace(/'/g, "''");
}

// Nome e e-mail só são lidos, nunca alterados
function buscarPorId(idUsuario) {
    var instrucao = `
        SELECT idUsuario, nome, email
        FROM usuario
        WHERE idUsuario = ${Number(idUsuario)};
    `;
    return database.executar(instrucao);
}

// Confere se a senha informada bate com a do banco
function validarSenhaAtual(idUsuario, senhaAtual) {
    var instrucao = `
        SELECT idUsuario
        FROM usuario
        WHERE idUsuario = ${Number(idUsuario)}
          AND senha = '${esc(senhaAtual)}';
    `;
    return database.executar(instrucao);
}

function atualizarSenha(idUsuario, novaSenha) {
    var instrucao = `
        UPDATE usuario
        SET senha = '${esc(novaSenha)}'
        WHERE idUsuario = ${Number(idUsuario)};
    `;
    return database.executar(instrucao);
}

module.exports = {
    buscarPorId,
    validarSenhaAtual,
    atualizarSenha
};
