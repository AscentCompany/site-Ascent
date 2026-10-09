var database = require("../../database/config")

function autenticar(email, senha) {
    console.log("ACESSEI O USUARIO MODEL \n \n\t\t >> Se aqui der erro de 'Error: connect ECONNREFUSED',\n \t\t >> verifique suas credenciais de acesso ao banco\n \t\t >> e se o servidor de seu BD está rodando corretamente. \n\n function entrar(): ", email, senha)
    var instrucaoSql = `
        SELECT idUsuario, nome, email, fkCompanhia, fkCargo FROM usuario WHERE email = '${email}' AND senha = '${senha}';
    `;
    console.log("Executando a instrução SQL: \n" + instrucaoSql);
    return database.executar(instrucaoSql);
}

// Coloque os mesmos parâmetros aqui. Vá para a var instrucaoSql
function cadastrar(nome, email, senha, idCompanhia) {
    console.log("ACESSEI O USUARIO MODEL \n \n\t\t >> Se aqui der erro de 'Error: connect ECONNREFUSED',\n \t\t >> verifique suas credenciais de acesso ao banco\n \t\t >> e se o servidor de seu BD está rodando corretamente. \n\n function cadastrar():", nome, email, senha, idCompanhia);
    
    // Insira exatamente a query do banco aqui, lembrando da nomenclatura exata nos valores
    //  e na ordem de inserção dos dados.
    var instrucaoSql = `
        INSERT INTO usuario (nome, email, senha, fkCompanhia, fkCargo)
        VALUES (
                       '${nome}',
                       '${email}',
                       '${senha}',
                       '${idCompanhia}',
                       (SELECT idCargo FROM cargo WHERE fkCompanhia = ${idCompanhia} ORDER BY idCargo ASC LIMIT 1)
            );
    `;
    console.log("Executando a instrução SQL: \n" + instrucaoSql);
    return database.executar(instrucaoSql);
}

// funcoes da tela de gerencia
function verificarPermissaoAdmin(idCompanhia) {
    var instrucaoSql = `SELECT MIN(idCargo) as adminCargo FROM cargo WHERE fkCompanhia = ${idCompanhia};`;
    return database.executar(instrucaoSql);
}

function listarCargos(idCompanhia) {
    var instrucaoSql = `SELECT idCargo, cargo FROM cargo WHERE fkCompanhia = ${idCompanhia} ORDER BY idCargo ASC;`;
    return database.executar(instrucaoSql);
}

function listarUsuariosCompanhia(idCompanhia) {
    var instrucaoSql = `
        SELECT u.idUsuario, u.nome, u.email, c.idCargo, c.cargo
        FROM usuario u
        JOIN cargo c ON u.fkCargo = c.idCargo
        WHERE u.fkCompanhia = ${idCompanhia};
    `;
    return database.executar(instrucaoSql);
}

function cadastrarFuncionario(nome, email, senha, idCompanhia, idCargo) {
    var instrucaoSql = `
        INSERT INTO usuario (nome, email, senha, fkCompanhia, fkCargo)
        VALUES ('${nome}', '${email}', '${senha}', ${idCompanhia}, ${idCargo});
    `;
    return database.executar(instrucaoSql);
}

function editarUsuario(idUsuario, email, fkCargo) {
    var instrucaoSql = `
        UPDATE usuario
        SET email = '${email}', fkCargo = ${fkCargo}
        WHERE idUsuario = ${idUsuario};
    `;
    return database.executar(instrucaoSql);
}

function deletarUsuario(idUsuario) {
    var instrucaoSql = `DELETE FROM usuario WHERE idUsuario = ${idUsuario};`;
    return database.executar(instrucaoSql);
}

module.exports = {
    autenticar,
    cadastrar,
    verificarPermissaoAdmin,
    listarCargos,
    listarUsuariosCompanhia,
    cadastrarFuncionario,
    editarUsuario,
    deletarUsuario
};
