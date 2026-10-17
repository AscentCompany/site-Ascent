var permissaoModel = require("../models/permissaoModel");

function listarPermissoes(req, res) {
    permissaoModel.listarPermissoes()
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarFuncionalidades(req, res) {
    permissaoModel.listarFuncionalidades()
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

module.exports = {
    listarPermissoes,
    listarFuncionalidades,

}