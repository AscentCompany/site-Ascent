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

  var nav = document.querySelector(".sidebar .nav");
  var indicator = nav && nav.querySelector(".nav-indicador");
  var items = nav ? Array.from(nav.querySelectorAll(".nav-item")) : [];
  var activeItem = items.find(function (item) {
    return item.classList.contains("ativo");
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
    return getHref(item) === previousHref;
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

  window.addEventListener("load", initializeIndicator);
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
})();
