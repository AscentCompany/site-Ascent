var express = require("express");
var router = express.Router();
var kpiController = require("../controllers/kpiController");

router.get("/benchmark/:idCompanhia", function (req, res) {
    kpiController.buscarDadosKpiBenchmark(req, res);
});

router.get("/volume-medio/:idCompanhia", function (req, res) {
    kpiController.buscarDadosKpiVolumeMedio(req, res);
});

router.get("/mes-maior-procura", function (req, res) {
    kpiController.buscarDadosKpiMesMaiorProcura(req, res);
});

module.exports = router;
