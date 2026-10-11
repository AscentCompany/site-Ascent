var express = require("express");
var router = express.Router();

var cargoController = require("../controllers/cargoController");


router.get("/permissao/:idCompanhia", function (req, res) {
    cargoController.verificarPermissaoAdmin(req, res);
});

router.get("/cargos/:idCompanhia", function (req, res) {
    cargoController.listarCargos(req, res);
});

router.get("/permissoes", function (req, res) {
    cargoController.listarPermissoes(req, res);
});

router.post("/cadastrar", function (req, res) {
    cargoController.cadastrar(req, res);
});

module.exports = router;