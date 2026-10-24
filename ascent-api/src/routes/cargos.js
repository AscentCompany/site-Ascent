var express = require("express");
var router = express.Router();

var cargoController = require("../controllers/cargoController");


router.get("/permissao/:idCompanhia", function (req, res) {
    cargoController.verificarPermissaoAdmin(req, res);
});

router.get("/listar/:idCompanhia", function (req, res) {
    cargoController.listarCargos(req, res);
});

router.get("/permissoes", function (req, res) {
    cargoController.listarPermissoes(req, res);
});

router.post("/cadastrar", function (req, res) {
    cargoController.cadastrar(req, res);
});

router.delete("/deletar/:idCargo", function (req, res) {
    cargoController.deletar(req, res);
});

router.put("/atualizar/:idCargo", function (req, res) {
    cargoController.atualizar(req, res);
});

module.exports = router;