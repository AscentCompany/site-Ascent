(function () {
  var paginasAuth = ["login.html", "cadastro.html"];
  var paginaAtual = window.location.pathname.split("/").pop();
  var chaveTransicao = "transicaoAuthDestino";
  var transicaoPendente = sessionStorage.getItem(chaveTransicao);

  if (transicaoPendente) {
    sessionStorage.removeItem(chaveTransicao);

    var separador = transicaoPendente.lastIndexOf("|");
    var destino = transicaoPendente.slice(0, separador);
    var criadaEm = Number(transicaoPendente.slice(separador + 1));
    var movimentoReduzido = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (
      destino === paginaAtual &&
      Date.now() - criadaEm < 5000 &&
      !movimentoReduzido &&
      window.innerWidth > 900
    ) {
      document.documentElement.style.setProperty(
        "--auth-image-entry-offset",
        destino === "cadastro.html" ? "100%" : "-100%"
      );
      document.documentElement.classList.add("auth-image-entering");

      window.requestAnimationFrame(function () {
        window.requestAnimationFrame(function () {
          document.documentElement.classList.remove("auth-image-entering");
        });
      });
    }
  }

  document.addEventListener("click", function (event) {
    var elemento = event.target.closest("a[href], [onclick]");
    if (!elemento) {
      return;
    }

    var destino = elemento.getAttribute("href");
    if (!destino) {
      var navegacao = (elemento.getAttribute("onclick") || "").match(
        /window\.location(?:\.href)?\s*=\s*['"]([^'"]+)['"]/
      );
      destino = navegacao && navegacao[1];
    }

    if (!destino) {
      return;
    }

    var paginaDestino = new URL(destino, window.location.href).pathname.split("/").pop();
    if (paginasAuth.includes(paginaDestino) && paginaDestino !== paginaAtual) {
      sessionStorage.setItem(chaveTransicao, paginaDestino + "|" + Date.now());
    }
  }, true);
})();
