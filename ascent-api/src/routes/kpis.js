var express = require("express");
var router = express.Router();
var kpiController = require("../controllers/kpiController");
var cache = require("../middlewares/cache");

router.get("/benchmark/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiBenchmark(req, res);
});

router.get("/volume-medio/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiVolumeMedio(req, res);
});

router.get("/mes-maior-procura", cache(15), function (req, res) {
    kpiController.buscarDadosKpiMesMaiorProcura(req, res);
});

router.get("/ocupacao-media/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiOcupacaoMedia(req, res);
});

router.get("/rotas/maior-incidencia/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiRotaMaiorIncidencia(req, res);
});

router.get("/rotas/aeroporto-menor-procura/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiAeroportoMenorProcura(req, res);
});

router.get("/rotas/hub-maior-circulacao/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiHubMaiorCirculacao(req, res);
});

router.get("/rotas/mes-maior-procura/:idCompanhia", cache(15), function (req, res) {
    kpiController.buscarDadosKpiMesMaiorProcuraRotas(req, res);
});

module.exports = router;
