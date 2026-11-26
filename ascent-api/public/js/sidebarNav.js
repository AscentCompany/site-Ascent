(function () {
  var storageKey = "sidebarPreviousHref";
  var gestaoStorageKey = "gestaoPreviousHref";
  var sidebarStateKey = "gestaoSidebarState";
  var legacyStorageKey = "navAnterior";
  var gestaoNav = document.querySelector(".gestao-nav");

  if (gestaoNav) {
    var gestaoIndicator = document.createElement("span");
    gestaoIndicator.className = "gestao-nav-indicador";
    gestaoIndicator.setAttribute("aria-hidden", "true");
    gestaoNav.prepend(gestaoIndicator);

    var previousGestaoHref = sessionStorage.getItem(gestaoStorageKey);
    sessionStorage.removeItem(gestaoStorageKey);
    var activeGestaoLink = gestaoNav.querySelector("a.ativo[href]");
    var previousGestaoLink = Array.from(gestaoNav.querySelectorAll("a[href]")).find(function (link) {
      return new URL(link.href, window.location.href).pathname === previousGestaoHref;
    });
    var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    function positionGestaoIndicator(link, animate) {
      if (!link) {
        return;
      }

      var linkRect = link.getBoundingClientRect();
      var navRect = gestaoNav.getBoundingClientRect();
      gestaoIndicator.style.transition = animate && !reduceMotion ? "" : "none";
      gestaoIndicator.style.width = linkRect.width + "px";
      gestaoIndicator.style.height = linkRect.height + "px";
      gestaoIndicator.style.transform = "translate(" +
        (linkRect.left - navRect.left - gestaoNav.clientLeft + gestaoNav.scrollLeft) + "px, " +
        (linkRect.top - navRect.top - gestaoNav.clientTop + gestaoNav.scrollTop) + "px)";
      gestaoIndicator.style.opacity = "1";
    }

    function initializeGestaoIndicator() {
      if (previousGestaoLink && activeGestaoLink && previousGestaoLink !== activeGestaoLink && !reduceMotion) {
        positionGestaoIndicator(previousGestaoLink, false);
        gestaoIndicator.getBoundingClientRect();
        requestAnimationFrame(function () {
          positionGestaoIndicator(activeGestaoLink, true);
        });
        return;
      }

      positionGestaoIndicator(activeGestaoLink, false);
    }

    window.addEventListener("load", initializeGestaoIndicator);
    window.addEventListener("resize", function () {
      positionGestaoIndicator(activeGestaoLink, false);
    });

    gestaoNav.addEventListener("click", function (event) {
      var link = event.target.closest("a[href]");
      if (!link || link.target === "_blank") {
        return;
      }

      var destination = new URL(link.href, window.location.href);
      if (destination.origin === window.location.origin) {
        sessionStorage.setItem(sidebarStateKey, document.body.classList.contains("menu-fechado") ? "closed" : "open");
        sessionStorage.removeItem(storageKey);

        var activeLink = gestaoNav.querySelector("a.ativo[href]");
        if (activeLink) {
          sessionStorage.setItem(gestaoStorageKey, new URL(activeLink.href, window.location.href).pathname);
        }
      }
    });
  }


  function aplicarControleAcessoPagina() {
    var funcionalidadesPorPagina = {
      "dashboardrotas.html": "Visualizar Dashboard de Rotas",
      "dashboardoperacoes.html": "Visualizar Dashboard de Operações",
      "centralalertas.html": "Configurar Regras de Alertas",
      "centralrecomendacoes.html": "Visualizar Central de Recomendações",
      "configuraralertas.html": "Configurar Regras de Alertas",
      "perfil.html": "Editar Informações de Usuário"
    };
    var pagina = window.location.pathname.split("/").pop().toLowerCase();
    var funcionalidade = funcionalidadesPorPagina[pagina];

    if (!funcionalidade) {
      return;
    }

    var cacheFuncionalidades = typeof obterFuncionalidadesCargoCache === "function"
      ? obterFuncionalidadesCargoCache()
      : null;

    if (cacheFuncionalidades !== null) {
      if (cacheFuncionalidades.indexOf(funcionalidade) === -1) {
        alert("Você não tem permissão para acessar esta página.");
        window.location.href = "acessoRapido.html";
      }
      return;
    }

    document.documentElement.style.visibility = "hidden";
    exigirFuncionalidadePagina(funcionalidade, "acessoRapido.html")
      .then(function (podeAcessar) {
        if (podeAcessar) {
          document.documentElement.style.visibility = "";
        }
      });
  }

  function aplicarPermissoesSidebar() {
    var regras = [
      { arquivo: "dashboardrotas.html", funcionalidade: "Visualizar Dashboard de Rotas" },
      { arquivo: "dashboardoperacoes.html", funcionalidade: "Visualizar Dashboard de Operações" },
      { arquivo: "usuarios.html", funcionalidade: "Gerenciar Funcionários e Cargos" },
      { arquivo: "cargos.html", funcionalidade: "Gerenciar Funcionários e Cargos" },
      { arquivo: "permissoes.html", funcionalidade: "Gerenciar Funcionários e Cargos" },
      { arquivo: "centralalertas.html", funcionalidade: "Configurar Regras de Alertas" },
      { arquivo: "centralrecomendacoes.html", funcionalidade: "Visualizar Central de Recomendações" },
      { arquivo: "configuraralertas.html", funcionalidade: "Configurar Regras de Alertas" },
      { arquivo: "perfil.html", funcionalidade: "Editar Informações de Usuário" }
    ];

    var navEl = document.querySelector(".sidebar .nav");
    var acessoGrid = document.querySelector(".acesso-grid");

    function aplicarRegras(funcionalidades) {
      var links = document.querySelectorAll(".sidebar .nav a[href], .acesso-grid a[href]");
      links.forEach(function (link) {
        var destino = link.getAttribute("href").toLowerCase();
        var regra = regras.find(function (item) {
          return destino.indexOf(item.arquivo) !== -1;
        });

        if (!regra) {
          return;
        }

        var elemento = link.closest(".nav-item") || link;
        elemento.style.display = funcionalidades.indexOf(regra.funcionalidade) !== -1 ? "" : "none";
      });

      if (navEl) {
        navEl.style.visibility = "";
      }
      if (acessoGrid) {
        acessoGrid.style.visibility = "";
      }
    }

    var cacheFuncionalidades = typeof obterFuncionalidadesCargoCache === "function"
      ? obterFuncionalidadesCargoCache()
      : null;

    if (cacheFuncionalidades !== null) {
      aplicarRegras(cacheFuncionalidades);
      return Promise.resolve(cacheFuncionalidades);
    }

    if (navEl) {
      navEl.style.visibility = "hidden";
    }
    if (acessoGrid) {
      acessoGrid.style.visibility = "hidden";
    }

    return carregarFuncionalidadesCargo()
      .then(aplicarRegras)
      .catch(function (erro) {
        console.error("Erro ao carregar permissões da navegação:", erro);
        aplicarRegras([]);
      });
  }

  aplicarControleAcessoPagina();
  aplicarPermissoesSidebar().then(inicializarIndicadorSidebar);

  function inicializarIndicadorSidebar() {
    var nav = document.querySelector(".sidebar .nav");
    var indicator = nav && nav.querySelector(".nav-indicador");
    var items = nav ? Array.from(nav.querySelectorAll(".nav-item")) : [];
    var activeItem = items.find(function (item) {
      return item.classList.contains("ativo") && getComputedStyle(item).display !== "none";
    });

    if (!nav || !indicator || !activeItem) {
      sessionStorage.removeItem(storageKey);
      sessionStorage.removeItem(legacyStorageKey);
      return;
    }

    var previousHref = sessionStorage.getItem(storageKey);
    sessionStorage.removeItem(storageKey);
    sessionStorage.removeItem(legacyStorageKey);

    function getHref(item) {
      var link = item && item.querySelector("a[href]");
      return link ? new URL(link.href, window.location.href).pathname : null;
    }

    function getOffset(item) {
      return item.getBoundingClientRect().top - nav.getBoundingClientRect().top;
    }

    function setPosition(item, animate) {
      if (!item || item.hidden || getComputedStyle(item).display === "none") {
        return;
      }

      indicator.style.transition = animate ? "" : "none";
      indicator.style.transform = "translateY(" + getOffset(item) + "px)";
      indicator.style.opacity = "1";
    }

    var previousItem = items.find(function (item) {
      return getHref(item) === previousHref && getComputedStyle(item).display !== "none";
    });

    function initializeIndicator() {
      if (previousItem && previousItem !== activeItem) {
        setPosition(previousItem, false);
        indicator.getBoundingClientRect();
        requestAnimationFrame(function () {
          setPosition(activeItem, true);
        });
        return;
      }

      setPosition(activeItem, false);
    }

    initializeIndicator();
    window.addEventListener("resize", function () {
      setPosition(activeItem, false);
    });

    document.addEventListener("click", function (event) {
      var link = event.target.closest(".sidebar .nav-item a[href]");
      if (!link || link.target === "_blank") {
        return;
      }

      var destination = new URL(link.href, window.location.href);
      if (destination.origin === window.location.origin) {
        sessionStorage.setItem(storageKey, getHref(activeItem));
      }
    }, true);
  }
})();
