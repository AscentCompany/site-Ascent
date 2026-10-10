var express = require("express");
var router = express.Router();

var usuarioController = require("../controllers/cargoController");


router.get("/permissao/:idCompanhia", function (req, res) {
    usuarioController.verificarPermissaoAdmin(req, res);
});

router.get("/cargos/:idCompanhia", function (req, res) {
    usuarioController.listarCargos(req, res);
});

module.exports = router;