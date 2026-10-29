let idCompanhia = Number(sessionStorage.COMPANHIA_USUARIO) || 1;
let ehGestor = Number(sessionStorage.CARGO_USUARIO) <= 2;


function janelaTexto(janela, inicio, fim) {
  if (janela === "personalizado" && inicio && fim) {
    const meses = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"];
    return meses[Number(inicio.slice(5,7)) - 1] + "/" + inicio.slice(0,4) + " → " + meses[Number(fim.slice(5,7)) - 1] + "/" + fim.slice(0,4);
  }
  return {"1_ano":"1 ano","3_anos":"3 anos","5_anos":"5 anos","10_anos":"10 anos","todo_historico":"Todo o histórico"}[janela] || janela;
}


function atualizarBadge() {
  fetch("/alertas/contar/" + idCompanhia)
    .then(r => r.json())
    .then(data => {
      const badge = document.getElementById("sino-badge");
      const total = data.total || 0;

      badge.innerHTML = total > 99 ? "99+" : total;
      badge.style.display = total > 0 ? "flex" : "none";
    });
}

function abrirPainel() {
  const painel = document.getElementById("painel-alertas");
  painel.style.display = painel.style.display === "none" ? "block" : "none";

  if (painel.style.display === "block") carregarPainel();
}

function fecharPainel() {
  const painel = document.getElementById("painel-alertas");
  if (painel) painel.style.display = "none";
}


function carregarPainel() {
  fetch("/alertas/listar/" + idCompanhia)
    .then(r => r.json())
    .then(alertas => {
      const lista = document.getElementById("painel-lista");

      if (!alertas.length) {
        lista.innerHTML = '<div class="painel-vazio">Nenhum alerta no momento.</div>';
        return;
      }

      let html = "";
      for (let i = 0; i < 5 && i < alertas.length; i++) {
        const a = alertas[i];
        html += '<div class="painel-item' + (!a.lida ? " nao-lida" : "") + '" onclick="abrirModal(' + a.idAlerta + ')">';
        html += '<span class="painel-sev">' + (a.severidade === "critico" ? "🔴" : "🟡") + '</span>';
        html += '<div class="painel-info"><div class="painel-rota">' + a.rota + '</div>';
        html += '<div class="painel-ocup">' + Number(a.ocupacaoMedia).toFixed(1) + '% de ocupação média</div></div>';
        html += '<span class="painel-seta">›</span></div>';
      }
      lista.innerHTML = html;
    });
}

function marcarTodas() {
  fetch("/alertas/todas-lidas/" + idCompanhia, { method: "PUT" }).then(() => {
    atualizarBadge();
    carregarPainel();
  });
}

function fecharModal() {
  document.getElementById("modal-alerta-container").innerHTML = "";
}


function abrirModal(idAlerta) {
  fecharPainel();

  fetch("/alertas/detalhe/" + idAlerta + "/" + idCompanhia)
    .then(r => r.json())
    .then(data => {
      const al = data.alerta;
      const hist = data.historico || [];

      let barras = "";
      for (let i = 0; i < hist.length; i++) {
        const h = hist[i];
        barras += '<div class="hist-linha">';
        barras += '<span class="hist-ano">' + h.ano + '</span>';
        barras += '<div class="hist-barra-bg"><div class="hist-barra-fill" style="width:' + Math.min(h.ocupacaoMedia, 100) + '%"></div></div>';
        barras += '<span class="hist-pct">' + Number(h.ocupacaoMedia).toFixed(1) + '%</span>';
        barras += '</div>';
      }

      let html = '<div class="modal-overlay-alerta">';
      html += '<div class="modal-alerta">';
      html += '<div class="modal-alerta-header">';
      html += '<h2>' + (al.severidade === "critico" ? "🔴" : "🟡") + ' ' + al.rota + ' — Ocupação ' + (al.severidade === "critico" ? "Crítica" : "em Atenção") + '</h2>';
      html += '<button class="modal-fechar" onclick="fecharModal()"><i class="fas fa-xmark"></i></button>';
      html += '</div>';
      html += '<div class="modal-alerta-body"><div class="modal-meta">';
      html += '<div class="modal-meta-item"><label>Ocupação média da rota</label><span class="' + al.severidade + '">' + Number(al.ocupacaoMedia).toFixed(1) + '%</span></div>';
      html += '<div class="modal-meta-item"><label>Alerta dispara quando</label><span>ocupação abaixo de ' + Number(al.faixaOcupacao).toFixed(0) + '%</span></div>';
      html += '<div class="modal-meta-item"><label>Período analisado</label><span>' + janelaTexto(al.janelaAnalise, al.janelaInicio, al.janelaFim) + '</span></div>';
      html += '</div>';

      if (hist.length) html += '<div class="modal-historico"><h4>Ocupação média por ano</h4>' + barras + '</div>';

      html += '</div>';
      html += '<div class="modal-alerta-footer">';
      html += '<button class="btn-modal-sec" onclick="fecharModal()">Fechar</button>';
      html += '<a class="btn-modal-prim" href="/dashboard/dashboardRotas.html">Ver no dashboard <i class="fas fa-arrow-right"></i></a>';
      html += '</div></div></div>';

      document.getElementById("modal-alerta-container").innerHTML = html;
      fetch("/alertas/lida/" + idAlerta + "/" + idCompanhia, { method: "PUT" }).then(atualizarBadge);
    });
}


window.onload = function() {
  const btnFiltrar = document.querySelector(".btn-filtrar");
  if (!btnFiltrar) return;

  const pai = btnFiltrar.parentNode;
  const grupo = document.createElement("div");
  grupo.style.cssText = "display:flex;align-items:center;gap:0;position:relative;";
  pai.replaceChild(grupo, btnFiltrar);

  let sinoHtml = '<div class="sino-wrapper" id="sino-wrapper">';
  sinoHtml += '<button class="sino-btn" onclick="abrirPainel()" title="Alertas"><i class="fas fa-bell"></i></button>';
  sinoHtml += '<span id="sino-badge" style="display:none;">0</span>';
  sinoHtml += '<div class="painel-alertas" id="painel-alertas" style="display:none;">';
  sinoHtml += '<div class="painel-header"><h3>Alertas</h3><div class="painel-acoes">';
  sinoHtml += '<button class="painel-btn-icon" onclick="marcarTodas()" title="Marcar todas como lidas"><i class="fas fa-check-double"></i></button>';

  if (ehGestor) sinoHtml += '<a href="/dashboard/configurarAlertas.html" class="painel-btn-icon" title="Configurar alertas"><i class="fas fa-gear"></i></a>';

  sinoHtml += '</div></div>';
  sinoHtml += '<div class="painel-lista" id="painel-lista"></div>';
  sinoHtml += '<div class="painel-footer"><a href="/dashboard/centralAlertas.html">Mostrar todas</a></div>';
  sinoHtml += '</div></div>';

  grupo.innerHTML = sinoHtml;
  grupo.appendChild(btnFiltrar);
  atualizarBadge();
};
