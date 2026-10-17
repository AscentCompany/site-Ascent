var database = require("../../database/config")

function listarPermissoes() {
    var instrucaoSql = `
        SELECT
            p.idPermissao,
            p.nome AS permissao,
            f.idFuncionalidade,
            f.nome AS funcionalidade,
            pf.idpermissaoFuncionalidade
        FROM permissao p
                 JOIN funcionalidade f
                 LEFT JOIN permissaoFuncionalidade pf
                           ON pf.fkPermissao = p.idPermissao AND pf.fkFuncionalidade = f.idFuncionalidade
        ORDER BY p.idPermissao ASC, f.idFuncionalidade ASC;
    `;
    return database.executar(instrucaoSql);
}

function listarFuncionalidades() {
    return database.executar(`SELECT * FROM funcionalidade;`);
}

function cadastrarPermissao(nomePermissao) {
    return database.executar(`INSERT INTO permissao (nome) VALUES ('${nomePermissao}');`);
}

function cadastrarPermissaoFuncionalidade(idPermissao, idFuncionalidade) {
    return database.executar(`INSERT INTO permissaoFuncionalidade (fkPermissao, fkFuncionalidade) VALUES (${idPermissao}, ${idFuncionalidade});`);
}

function buscarUltimaPermissao() {
    return database.executar(`SELECT MAX(idPermissao) as idNovaPermissao FROM permissao;`);
}

function deletarPermissaoFuncionalidades(idPermissao) {
    return database.executar(`DELETE FROM permissaoFuncionalidade WHERE fkPermissao = ${idPermissao};`);
}

function deletarPermissao(idPermissao) {
    return database.executar(`DELETE FROM permissao WHERE idPermissao = ${idPermissao};`);
}

function buscarCargosDaPermissao(idPermissao) {
    var instrucaoSql = `
        SELECT c.cargo
        FROM cargo c
        JOIN cargoPermissao cp ON c.idCargo = cp.fkCargo
        WHERE cp.fkPermissao = ${idPermissao};
    `;
    return database.executar(instrucaoSql);
}

function deletarCargoPermissoesPorPermissao(idPermissao) {
    return database.executar(`DELETE FROM cargoPermissao WHERE fkPermissao = ${idPermissao};`);
}

function contarPermissoes() {
    var instrucaoSql = `SELECT COUNT(idPermissao) AS qtd FROM permissao;`;
    return database.executar(instrucaoSql);
}

module.exports = {
    listarPermissoes,
    listarFuncionalidades,
    cadastrarPermissao,
    cadastrarPermissaoFuncionalidade,
    buscarUltimaPermissao,
    deletarPermissaoFuncionalidades,
    deletarPermissao,
    buscarCargosDaPermissao,
    deletarCargoPermissoesPorPermissao,
    contarPermissoes
};