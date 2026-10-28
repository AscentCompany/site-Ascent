var database = require("../../database/config")

function verificarPermissaoAdmin(idCompanhia) {
    var instrucaoSql = `SELECT MIN(idCargo) as adminCargo FROM cargo WHERE fkCompanhia = ${idCompanhia};`;
    return database.executar(instrucaoSql);
}

function listarCargos(idCompanhia) {
    var instrucaoSql = `
        SELECT
            c.idCargo,
            c.cargo,
            p.idPermissao,
            p.nomePermissao AS permissao,
            cp.fkCargo AS idCargoPermissao
        FROM cargo c
                 JOIN permissao p
                 LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
        WHERE c.fkCompanhia = ${idCompanhia}
        ORDER BY c.idCargo ASC;
    `;
    return database.executar(instrucaoSql);
}

function listarPermissoes() {
    return database.executar(`SELECT idPermissao, nomePermissao AS nome FROM permissao;`);
}

function cadastrarCargo(nomeCargo, idCompanhia) {
    return database.executar(`INSERT INTO cargo (cargo, fkCompanhia) VALUES ('${nomeCargo}', ${idCompanhia});`);
}

function cadastrarCargoPermissao(idCargo, idPermissao) {
    return database.executar(`INSERT INTO cargoPermissao (fkCargo, fkPermissao) VALUES (${idCargo}, ${idPermissao});`);
}

function buscarUltimoCargo(idCompanhia) {
    var instrucaoSql = `SELECT MAX(idCargo) as idNovoCargo FROM cargo WHERE fkCompanhia = ${idCompanhia};`;
    return database.executar(instrucaoSql);
}

function deletarCargoPermissoes(idCargo) {
    var instrucaoSql = `DELETE FROM cargoPermissao WHERE fkCargo = ${idCargo};`;
    return database.executar(instrucaoSql);
}

function deletarCargo(idCargo) {
    var instrucaoSql = `DELETE FROM cargo WHERE idCargo = ${idCargo};`;
    return database.executar(instrucaoSql);
}


module.exports = {
    verificarPermissaoAdmin,
    listarCargos,
    listarPermissoes,
    cadastrarCargo,
    cadastrarCargoPermissao,
    buscarUltimoCargo,
    deletarCargoPermissoes,
    deletarCargo
};
