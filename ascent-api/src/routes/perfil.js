var express = require("express");
var router = express.Router();

var perfilController = require("../controllers/perfilController");

// PUT /perfil/senha  -> altera a senha
router.put("/senha", function (req, res) {
    perfilController.alterarSenha(req, res);
});

// GET /perfil/:idUsuario  -> traz nome e e-mail
router.get("/:idUsuario", function (req, res) {
    perfilController.buscar(req, res);
});

module.exports = router;
