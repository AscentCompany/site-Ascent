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
            p.nome AS permissao,
            cp.idCargoPermissao
        FROM cargo c
                 JOIN permissao p
                 LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
        WHERE c.fkCompanhia = ${idCompanhia}
        ORDER BY c.idCargo ASC;
    `;
    return database.executar(instrucaoSql);
}
module.exports = {
    verificarPermissaoAdmin,
    listarCargos
};
