let express = require("express");
let router = express.Router();
let alertaController = require("../controllers/alertaController");

router.get("/regras/:idCompanhia", function(req, res) {
    alertaController.listarRegras(req, res);
});

router.post("/regras", function(req, res) {
    alertaController.criarRegra(req, res);
});

router.put("/regras/:idRegra", function(req, res) {
    alertaController.editarRegra(req, res);
});

router.delete("/regras/:idRegra/:idCompanhia", function(req, res) {
    alertaController.excluirRegra(req, res);
});

router.get("/listar/:idCompanhia", function(req, res) {
    alertaController.listarAlertas(req, res);
});

router.get("/contar/:idCompanhia", function(req, res) {
    alertaController.contarNaoLidas(req, res);
});

router.get("/detalhe/:idAlerta/:idCompanhia", function(req, res) {
    alertaController.detalheAlerta(req, res);
});

router.put("/lida/:idAlerta/:idCompanhia", function(req, res) {
    alertaController.marcarLida(req, res);
});

router.put("/todas-lidas/:idCompanhia", function(req, res) {
    alertaController.marcarTodasLidas(req, res);
});

module.exports = router;
