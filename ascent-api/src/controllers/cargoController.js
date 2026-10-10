var cargoModel = require("../models/cargoModel");

function verificarPermissaoAdmin(req, res) {
    var idCompanhia = req.params.idCompanhia;
    cargoModel.verificarPermissaoAdmin(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarCargos(req, res) {
    var idCompanhia = req.params.idCompanhia;
    cargoModel.listarCargos(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

module.exports = {
    verificarPermissaoAdmin,
    listarCargos,

}