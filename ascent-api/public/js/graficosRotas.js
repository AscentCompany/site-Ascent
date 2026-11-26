Chart.defaults.font.family = '"Nunito Sans", "Segoe UI", Arial, sans-serif';
Chart.defaults.color = '#2b2b2b';

const mesesRotas = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
const horariosRotas = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
const coresBarrasRotas = [
  '#f5df7a', '#e9ec6a', '#78e05b', '#ff8a1f', '#ea4a0c',
  '#4fd8cf', '#ffb866', '#dca8ee', '#ffa87a'
];
let detalhesRotasGrafico = [];

/* 1) Demanda por tipo de voos (linhas) */
const graficoLinhasRotas = new Chart(document.getElementById('grafico-linhas'), {
  type: 'line',
  data: {
    labels: mesesRotas,
    datasets: [
      {
        label: 'Comerciais',
        data: new Array(12).fill(0),
        borderColor: '#9ea4ac',
        backgroundColor: '#9ea4ac',
        tension: 0,
        pointRadius: 4.5,
        pointHoverRadius: 6,
        pointBackgroundColor: '#9ea4ac',
        pointBorderColor: '#9ea4ac',
        borderWidth: 2.5
      },
      {
        label: 'Turísticos',
        data: new Array(12).fill(0),
        borderColor: '#ff6a00',
        backgroundColor: '#ff6a00',
        tension: 0,
        pointRadius: 4.5,
        pointHoverRadius: 6,
        pointBackgroundColor: '#ff6a00',
        pointBorderColor: '#ff6a00',
        borderWidth: 2.5
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: {
        position: 'top',
        align: 'end',
        labels: {
          boxWidth: 8,
          boxHeight: 8,
          usePointStyle: true,
          pointStyle: 'circle',
          font: { size: 10 },
          color: '#555'
        }
      },
      tooltip: {
        callbacks: {
          label: function (ctx) {
            return ` ${ctx.dataset.label}: ${Number(ctx.parsed.y || 0).toLocaleString('pt-BR')} passageiros`;
          }
        }
      }
    },
    scales: {
      x: {
        grid: { display: false },
        border: { display: false },
        ticks: { font: { size: 10 }, color: '#777' }
      },
      y: {
        beginAtZero: true,
        grid: { color: '#ececec' },
        border: { display: false },
        ticks: {
          maxTicksLimit: 5,
          font: { size: 10 },
          color: '#777',
          callback: function (valor) {
            return Number(valor).toLocaleString('pt-BR');
          }
        },
        title: {
          display: true,
          text: 'Passageiros Transportados',
          font: { size: 10, weight: '600' },
          color: '#555'
        }
      }
    }
  }
});

/* 2) Demanda por tipo de voos por horário */
const graficoHorarioRotas = new Chart(document.getElementById('grafico-horario'), {
  type: 'line',
  data: {
    labels: horariosRotas,
    datasets: [
      {
        label: 'Comerciais',
        data: new Array(6).fill(0),
        borderColor: '#9ea4ac',
        backgroundColor: '#9ea4ac',
        tension: 0,
        pointRadius: 4.5,
        pointHoverRadius: 6,
        pointBackgroundColor: '#9ea4ac',
        pointBorderColor: '#9ea4ac',
        borderWidth: 2.5
      },
      {
        label: 'Turísticos',
        data: new Array(6).fill(0),
        borderColor: '#ff6a00',
        backgroundColor: '#ff6a00',
        tension: 0,
        pointRadius: 4.5,
        pointHoverRadius: 6,
        pointBackgroundColor: '#ff6a00',
        pointBorderColor: '#ff6a00',
        borderWidth: 2.5
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: {
        position: 'top',
        align: 'end',
        labels: {
          boxWidth: 8,
          boxHeight: 8,
          usePointStyle: true,
          pointStyle: 'circle',
          font: { size: 10 },
          color: '#555'
        }
      },
      tooltip: {
        callbacks: {
          label: function (ctx) {
            return ` ${ctx.dataset.label}: ${Number(ctx.parsed.y || 0).toLocaleString('pt-BR')} passageiros`;
          }
        }
      }
    },
    scales: {
      x: {
        grid: { display: false },
        border: { display: false },
        ticks: { font: { size: 10 }, color: '#777' }
      },
      y: {
        beginAtZero: true,
        grid: { color: '#ececec' },
        border: { display: false },
        ticks: {
          maxTicksLimit: 5,
          font: { size: 10 },
          color: '#777',
          callback: function (valor) {
            return Number(valor).toLocaleString('pt-BR');
          }
        },
        title: {
          display: true,
          text: 'Quantidade de passageiros',
          font: { size: 10, weight: '600' },
          color: '#555'
        }
      }
    }
  }
});

/* 3) Demanda por rota (barras horizontais) */
const graficoBarrasRotas = new Chart(document.getElementById('grafico-barras'), {
  type: 'bar',
  data: {
    labels: [],
    datasets: [{
      label: 'Demanda',
      data: [],
      backgroundColor: [],
      borderRadius: 4,
      categoryPercentage: 0.9,
      barPercentage: 0.85
    }]
  },
  options: {
    indexAxis: 'y',
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', axis: 'y', intersect: false },
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          title: function (contextos) {
            let indice = contextos[0] ? contextos[0].dataIndex : -1;
            let detalhe = detalhesRotasGrafico[indice];
            return detalhe && detalhe.nomeCompletoRota
              ? `${detalhe.rota} (${detalhe.nomeCompletoRota})`
              : (contextos[0] ? contextos[0].label : '');
          },
          label: function (ctx) {
            let indice = ctx.dataIndex;
            let detalhe = detalhesRotasGrafico[indice];
            let voos = Number(ctx.parsed.x || 0).toLocaleString('pt-BR');
            if (detalhe && detalhe.totalPassageiros) {
              return ` ${voos} voos (${Number(detalhe.totalPassageiros).toLocaleString('pt-BR')} passageiros)`;
            }
            return ` ${voos} voos`;
          }
        }
      }
    },
    scales: {
      x: {
        beginAtZero: true,
        grid: { color: '#ececec' },
        ticks: {
          maxTicksLimit: 6,
          font: { size: 10 },
          callback: function (valor) {
            if (valor === 0) return '0';
            if (valor >= 1000) {
              return (valor / 1000).toLocaleString('pt-BR', { maximumFractionDigits: 1 }) + 'mil';
            }
            return Number(valor).toLocaleString('pt-BR');
          }
        }
      },
      y: {
        grid: { display: false },
        ticks: { font: { size: 10 } }
      }
    }
  }
});

function definirEstadoGraficoRotas(idElemento, mensagem) {
  let el = document.getElementById(idElemento);
  if (el) {
    el.textContent = mensagem;
  }
}

const canvasBarrasRotas = document.getElementById('grafico-barras');
if (canvasBarrasRotas) {
  canvasBarrasRotas.addEventListener('mousemove', function (evento) {
    let escalaY = graficoBarrasRotas.scales && graficoBarrasRotas.scales.y;
    if (!escalaY || !detalhesRotasGrafico.length) {
      canvasBarrasRotas.title = '';
      return;
    }

    let retangulo = canvasBarrasRotas.getBoundingClientRect();
    let x = evento.clientX - retangulo.left;
    let y = evento.clientY - retangulo.top;

    if (x >= escalaY.left && x <= escalaY.right && y >= escalaY.top && y <= escalaY.bottom) {
      let indice = escalaY.getValueForPixel(y);
      let detalhe = detalhesRotasGrafico[indice];
      if (detalhe && detalhe.nomeCompletoRota) {
        canvasBarrasRotas.title = `${detalhe.rota}: ${detalhe.nomeCompletoRota}`;
        canvasBarrasRotas.style.cursor = 'help';
        return;
      }
    }

    canvasBarrasRotas.title = '';
    canvasBarrasRotas.style.cursor = '';
  });

  canvasBarrasRotas.addEventListener('mouseleave', function () {
    canvasBarrasRotas.title = '';
    canvasBarrasRotas.style.cursor = '';
  });
}

function carregarGraficosRotas() {
  let companhiaId = Number(sessionStorage.COMPANHIA_USUARIO);
  let anoPadrao = new Date().getFullYear() - 1;
  document.getElementById('ano-grafico-linhas').textContent = anoPadrao;
  document.getElementById('ano-grafico-horario').textContent = anoPadrao;
  document.getElementById('ano-grafico-barras').textContent = anoPadrao;

  if (!Number.isInteger(companhiaId) || companhiaId <= 0) {
    definirEstadoGraficoRotas('status-grafico-linhas', 'Não foi possível identificar a companhia.');
    definirEstadoGraficoRotas('status-grafico-horario', 'Não foi possível identificar a companhia.');
    definirEstadoGraficoRotas('status-grafico-barras', 'Não foi possível identificar a companhia.');
    return;
  }

  fetch(`/api/graficos/rotas/${companhiaId}`)
    .then(function (resposta) {
      if (!resposta.ok) {
        throw new Error('Erro HTTP: ' + resposta.status);
      }
      return resposta.json();
    })
    .then(function (json) {
      if (!json.sucesso || !json.dados) {
        throw new Error('Resposta inválida da API');
      }

      let dados = json.dados;
      let demandaMensal = dados.demandaMensal;
      let demandaHorario = dados.demandaHorario;
      let demandaPorRota = dados.demandaPorRota;

      if (
        !demandaMensal ||
        !demandaHorario ||
        !Array.isArray(demandaPorRota) ||
        !Array.isArray(demandaMensal.comerciais) ||
        !Array.isArray(demandaMensal.turisticos) ||
        !Array.isArray(demandaHorario.comerciais) ||
        !Array.isArray(demandaHorario.turisticos)
      ) {
        throw new Error('Formato dos dados dos gráficos inválido');
      }

      document.getElementById('ano-grafico-linhas').textContent = dados.anoReferencia;
      document.getElementById('ano-grafico-horario').textContent = dados.anoReferencia;
      document.getElementById('ano-grafico-barras').textContent = dados.anoReferencia;

      graficoLinhasRotas.data.datasets[0].data = demandaMensal.comerciais;
      graficoLinhasRotas.data.datasets[1].data = demandaMensal.turisticos;
      graficoLinhasRotas.update();

      graficoHorarioRotas.data.datasets[0].data = demandaHorario.comerciais;
      graficoHorarioRotas.data.datasets[1].data = demandaHorario.turisticos;
      graficoHorarioRotas.update();

      detalhesRotasGrafico = demandaPorRota;
      graficoBarrasRotas.data.labels = demandaPorRota.map(function (r) { return r.rota; });
      graficoBarrasRotas.data.datasets[0].data = demandaPorRota.map(function (r) { return r.quantidadeVoos; });
      graficoBarrasRotas.data.datasets[0].backgroundColor = demandaPorRota.map(function (_, i) {
        return coresBarrasRotas[i % coresBarrasRotas.length];
      });
      graficoBarrasRotas.update();

      let semMensal = demandaMensal.comerciais.every(function (v) { return v === 0; })
        && demandaMensal.turisticos.every(function (v) { return v === 0; });
      let semHorario = demandaHorario.comerciais.every(function (v) { return v === 0; })
        && demandaHorario.turisticos.every(function (v) { return v === 0; });

      definirEstadoGraficoRotas(
        'status-grafico-linhas',
        semMensal ? 'Sem voos válidos da companhia no período.' : ''
      );
      definirEstadoGraficoRotas(
        'status-grafico-horario',
        semHorario ? 'Sem voos válidos da companhia no período.' : ''
      );
      definirEstadoGraficoRotas(
        'status-grafico-barras',
        demandaPorRota.length === 0 ? 'Sem rotas válidas da companhia no período.' : ''
      );
    })
    .catch(function (erro) {
      console.error('Erro ao carregar gráficos de rotas:', erro);
      definirEstadoGraficoRotas('status-grafico-linhas', 'Não foi possível carregar os dados.');
      definirEstadoGraficoRotas('status-grafico-horario', 'Não foi possível carregar os dados.');
      definirEstadoGraficoRotas('status-grafico-barras', 'Não foi possível carregar os dados.');
    });
}

carregarGraficosRotas();
