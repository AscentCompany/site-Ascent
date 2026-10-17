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
                 -- Cruza TODAS as permissões com TODAS as funcionalidades
                 CROSS JOIN funcionalidade f
            -- Verifica se existe o vínculo na tabela associativa
                 LEFT JOIN permissaoFuncionalidade pf
                           ON pf.fkPermissao = p.idPermissao AND pf.fkFuncionalidade = f.idFuncionalidade
        ORDER BY p.idPermissao ASC, f.idFuncionalidade ASC;
    `;
    return database.executar(instrucaoSql);
}

function listarFuncionalidades() {
    return database.executar(`SELECT * FROM funcionalidade;`);
}



module.exports = {
    listarPermissoes,
    listarFuncionalidades,
};