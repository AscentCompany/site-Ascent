var express = require("express");
var router = express.Router();

var permissaoController = require("../controllers/permissaoController");

router.get("/listar", function (req, res) {
    permissaoController.listarPermissoes(req, res);
});

router.get("/funcionalidades", function (req, res) {
    permissaoController.listarFuncionalidades(req, res);
});

router.post("/cadastrar", function (req, res) {
    permissaoController.cadastrar(req, res);
});

router.delete("/deletar/:idPermissao", function (req, res) {
    permissaoController.deletar(req, res);
});

router.put("/atualizar/:idPermissao", function (req, res) {
    permissaoController.atualizar(req, res);
});

router.get("/cargos-vinculados/:idPermissao", function (req, res) {
    permissaoController.buscarCargosVinculados(req, res);
});

module.exports = router;