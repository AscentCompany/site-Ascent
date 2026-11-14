var express = require("express");
var router = express.Router();
var kpiController = require("../controllers/kpiController");

router.get("/benchmark/:idCompanhia", function (req, res) {
    kpiController.buscarDadosKpiBenchmark(req, res);
});

module.exports = router;
