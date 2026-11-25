var express = require("express");
var router = express.Router();
var graficosController = require("../controllers/graficosController");
var cache = require("../middlewares/cache");

router.get("/informativo-rotas/:idCompanhia", cache(15), function (req, res) {
    graficosController.buscarInformativoRotas(req, res);
});

router.get("/operacoes/:idCompanhia", cache(15), function (req, res) {
    graficosController.buscarGraficosOperacoes(req, res);
});

module.exports = router;
