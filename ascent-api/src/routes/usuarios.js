var express = require("express");
var router = express.Router();

var usuarioController = require("../controllers/usuarioController");

//Recebendo os dados do html e direcionando para a função cadastrar de usuarioController.js
router.post("/cadastrar", function (req, res) {
    usuarioController.cadastrar(req, res);
})

router.post("/autenticar", function (req, res) {
    usuarioController.autenticar(req, res);
});


// Rotas da tela de gerenciamento de organização
router.get("/permissao/:idCompanhia", function (req, res) {
    usuarioController.verificarPermissaoAdmin(req, res);
});

router.get("/cargos/:idCompanhia", function (req, res) {
    usuarioController.listarCargos(req, res);
});

router.get("/listar/:idCompanhia", function (req, res) {
    usuarioController.listarUsuariosCompanhia(req, res);
});

router.post("/cadastrarFuncionario", function (req, res) {
    usuarioController.cadastrarFuncionario(req, res);
});

router.put("/editar/:idUsuario", function (req, res) {
    usuarioController.editarUsuario(req, res);
});

router.delete("/deletar/:idUsuario", function (req, res) {
    usuarioController.deletarUsuario(req, res);
});

module.exports = router;