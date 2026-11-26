function formatarTaxaOcupacao(valor) {
  return Number(valor).toLocaleString('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1
  }) + '%';
}

function renderizarRotas(elemento, rotas, classeOcupacao) {
  elemento.textContent = '';

  if (rotas.length === 0) {
    let linha = document.createElement('div');
    linha.className = 'linha-rota';
    let mensagem = document.createElement('span');
    mensagem.textContent = 'Sem dados no período';
    let quantidadeVoos = document.createElement('span');
    quantidadeVoos.textContent = '--';
    let ocupacao = document.createElement('span');
    ocupacao.textContent = '--';
    linha.append(mensagem, quantidadeVoos, ocupacao);
    elemento.appendChild(linha);
    return;
  }

  rotas.forEach(function (rota) {
    let linha = document.createElement('div');
    linha.className = 'linha-rota';

    let nomeRota = document.createElement('span');
    nomeRota.textContent = rota.rota;
    nomeRota.title = rota.nomeCompletoRota || rota.rota;

    let quantidadeVoos = document.createElement('span');
    quantidadeVoos.textContent = Number(rota.quantidadeVoos).toLocaleString('pt-BR');

    let ocupacao = document.createElement('span');
    ocupacao.className = `ocupacao ${classeOcupacao}`;
    ocupacao.textContent = formatarTaxaOcupacao(rota.taxaOcupacao);

    linha.append(nomeRota, quantidadeVoos, ocupacao);
    elemento.appendChild(linha);
  });
}

function definirEstadoInformativoRotas(mensagem) {
  renderizarRotas(document.getElementById('rotas-maior-ocupacao'), [], 'alta');
  renderizarRotas(document.getElementById('rotas-menor-ocupacao'), [], 'baixa');
  document.querySelector('#rotas-maior-ocupacao .linha-rota span:first-child').textContent = mensagem;
  document.querySelector('#rotas-menor-ocupacao .linha-rota span:first-child').textContent = mensagem;
  document.querySelector('#indicador-subutilizacao strong').textContent = '-- rotas';
  document.querySelector('#indicador-gargalo-demanda strong').textContent = '-- rotas';
}

function carregarInformativoRotas() {
  document.getElementById('ano-informativo-rotas').textContent =
    new Date().getFullYear() - 1;

  let companhiaId = Number(sessionStorage.COMPANHIA_USUARIO);
  if (!Number.isInteger(companhiaId) || companhiaId <= 0) {
    definirEstadoInformativoRotas('Não foi possível identificar a companhia.');
    return;
  }

  fetch(`/api/graficos/informativo-rotas/${companhiaId}`)
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

      document.getElementById('ano-informativo-rotas').textContent =
        json.dados.anoReferencia;

      renderizarRotas(
        document.getElementById('rotas-maior-ocupacao'),
        json.dados.rotasMaiorOcupacao,
        'alta'
      );
      renderizarRotas(
        document.getElementById('rotas-menor-ocupacao'),
        json.dados.rotasMenorOcupacao,
        'baixa'
      );

      let taxaMedia = json.dados.taxaOcupacaoMedia;
      let indicadorSubutilizacao = document.getElementById('indicador-subutilizacao');
      indicadorSubutilizacao.querySelector('small').textContent = taxaMedia === null
        ? 'Sem ocupação média disponível'
        : `Abaixo da ocupação média de ${formatarTaxaOcupacao(taxaMedia)}`;
      indicadorSubutilizacao.querySelector('strong').textContent =
        `${Number(json.dados.totalRotasSubutilizadas).toLocaleString('pt-BR')} rotas`;
      document.querySelector('#indicador-gargalo-demanda strong').textContent =
        `${Number(json.dados.totalRotasGargaloDemanda).toLocaleString('pt-BR')} rotas`;
    })
    .catch(function (erro) {
      console.error('Erro ao carregar informativo de rotas:', erro);
      definirEstadoInformativoRotas('Não foi possível carregar os dados.');
    });
}

carregarInformativoRotas();

const meses = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'
];
let quantidadeVoosMensais = new Array(12).fill(0);

function calcularJitter(capacidade, passageiros, indice, amplitude) {
  let amp = amplitude !== undefined ? amplitude : 4.5;
  let s = Math.sin(capacidade * 17.3 + passageiros * 31.7 + indice * 13.1);
  let normalizado = (s - Math.floor(s) - 0.5) * 2;
  return Number((normalizado * amp).toFixed(2));
}

function processarPontosDispersao(pontos, ehCompanhia, amplitudeJitter) {
  if (!Array.isArray(pontos)) return [];
  let resultado = [];
  for (let index = 0; index < pontos.length; index++) {
    let ponto = pontos[index];
    let capacidade = Number(ponto.x) || 0;
    let passageiros = Number(ponto.y) || 0;
    let quantidadeVoos = Number(ponto.quantidadeVoos) || 1;

    if (capacidade <= 0 || passageiros < 0) continue;

    let taxaOcupacao = (passageiros / capacidade) * 100;
    // Descarta inconsistências pontuais de registros (ex: erro ANAC com ocupação > 115%)
    if (taxaOcupacao > 115) continue;

    let jitterX = calcularJitter(capacidade, passageiros, index, amplitudeJitter);

    let raio = ehCompanhia
      ? Math.min(11, Math.max(3.5, Math.sqrt(quantidadeVoos) * 1.5))
      : Math.min(6, Math.max(1.8, Math.sqrt(quantidadeVoos) * 0.9));

    resultado.push({
      x: Number((capacidade + jitterX).toFixed(2)),
      y: Number(taxaOcupacao.toFixed(1)),
      r: raio,
      capacidadeReal: capacidade,
      passageirosReal: passageiros,
      taxaOcupacao: taxaOcupacao,
      quantidadeVoos: quantidadeVoos
    });
  }
  return resultado;
}

const graficoEvolucao = new Chart(document.getElementById('grafico-evolucao'), {
  type: 'scatter',
  data: {
    datasets: [
      {
        label: 'Mercado (todas as companhias)',
        data: [],
        backgroundColor: 'rgba(160, 160, 160, 0.22)',
        borderColor: 'rgba(160, 160, 160, 0.35)',
        borderWidth: 1,
        pointRadius: function (context) {
          return context.raw && context.raw.r ? context.raw.r : 2;
        },
        pointHoverRadius: function (context) {
          return (context.raw && context.raw.r ? context.raw.r : 2) + 2;
        },
        order: 3
      },
      {
        label: 'Sua companhia',
        data: [],
        backgroundColor: 'rgba(255, 106, 0, 0.55)',
        borderColor: '#ff6a00',
        borderWidth: 1.5,
        pointRadius: function (context) {
          return context.raw && context.raw.r ? context.raw.r : 4;
        },
        pointHoverRadius: function (context) {
          return (context.raw && context.raw.r ? context.raw.r : 4) + 3;
        },
        order: 2
      },
      {
        label: 'Capacidade Total (100%)',
        data: [],
        type: 'line',
        showLine: true,
        borderColor: 'rgba(40, 167, 69, 0.75)',
        borderWidth: 1.5,
        borderDash: [6, 4],
        pointRadius: 0,
        pointHoverRadius: 0,
        fill: false,
        order: 1
      },
      {
        label: 'Break-even da Indústria (75%)',
        data: [],
        type: 'line',
        showLine: true,
        borderColor: 'rgba(235, 150, 0, 0.85)',
        borderWidth: 1.5,
        borderDash: [4, 4],
        pointRadius: 0,
        pointHoverRadius: 0,
        fill: false,
        order: 1
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
        align: 'end',
        labels: {
          boxWidth: 14,
          boxHeight: 8,
          usePointStyle: true,
          font: { size: 10 },
          color: '#555'
        }
      },
      tooltip: {
        callbacks: {
          label: function (contexto) {
            let ponto = contexto.raw;
            if (!ponto || ponto.taxaOcupacao === undefined) {
              return ` ${contexto.dataset.label}`;
            }
            let quantidadeVoos = Number(ponto.quantidadeVoos) || 0;
            let vooLabel = quantidadeVoos === 1 ? 'voo' : 'voos';
            let taxa = ponto.taxaOcupacao.toLocaleString('pt-BR', {
              minimumFractionDigits: 1,
              maximumFractionDigits: 1
            }) + '%';
            return ` ${contexto.dataset.label}: ${taxa} de ocupação (${ponto.passageirosReal} pass. / ${ponto.capacidadeReal} assentos) [${Number(quantidadeVoos).toLocaleString('pt-BR')} ${vooLabel}]`;
          }
        }
      }
    },
    scales: {
      x: {
        type: 'linear',
        grid: { display: false },
        border: { display: false },
        ticks: {
          maxTicksLimit: 6,
          color: '#777',
          font: { size: 10 }
        },
        title: {
          display: true,
          text: 'Capacidade do Avião (Assentos)',
          color: '#555',
          font: { size: 10, weight: '600' }
        }
      },
      y: {
        min: 0,
        max: 115,
        grid: { color: '#ececec' },
        border: { display: false },
        ticks: {
          maxTicksLimit: 6,
          color: '#777',
          font: { size: 10 },
          callback: function (valor) {
            return valor + '%';
          }
        },
        title: {
          display: true,
          text: 'Taxa de Ocupação Real (%)',
          color: '#555',
          font: { size: 10, weight: '600' }
        }
      }
    }
  }
});

const graficoMensal = new Chart(document.getElementById('grafico-mensal'), {
  type: 'bar',
  data: {
    labels: meses,
    datasets: [
      {
        label: 'Média de passageiros por voo',
        data: new Array(12).fill(null),
        backgroundColor: '#ff6a00',
        borderRadius: 4,
        barPercentage: 0.52,
        categoryPercentage: 0.8,
        grouped: false,
        order: 1
      },
      {
        label: 'Média de assentos por voo',
        data: new Array(12).fill(null),
        backgroundColor: '#dfe3e8',
        borderRadius: 4,
        barPercentage: 0.85,
        categoryPercentage: 0.8,
        grouped: false,
        order: 2
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: {
        display: true,
        position: 'top',
        align: 'end',
        labels: {
          boxWidth: 12,
          boxHeight: 12,
          usePointStyle: true,
          pointStyle: 'rectRounded',
          font: { size: 11 },
          color: '#555'
        }
      },
      tooltip: {
        callbacks: {
          label: function (contexto) {
            let valor = Number(contexto.parsed.y).toLocaleString('pt-BR', {
              maximumFractionDigits: 1
            });
            return ` ${contexto.dataset.label}: ${valor}`;
          },
          footer: function (contextos) {
            let quantidade = quantidadeVoosMensais[contextos[0].dataIndex];
            let voosLabel = quantidade === 1 ? 'voo' : 'voos';
            return `Base: ${Number(quantidade).toLocaleString('pt-BR')} ${voosLabel}`;
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
          color: '#777',
          font: { size: 10 }
        }
      }
    }
  }
});

function definirEstadoGrafico(idElemento, mensagem) {
  document.getElementById(idElemento).textContent = mensagem;
}

function carregarGraficosOperacoes() {
  let companhiaId = Number(sessionStorage.COMPANHIA_USUARIO);
  let anoPadrao = new Date().getFullYear() - 1;
  document.getElementById('ano-grafico-evolucao').textContent = anoPadrao;
  document.getElementById('ano-grafico-mensal').textContent = anoPadrao;

  if (!Number.isInteger(companhiaId) || companhiaId <= 0) {
    definirEstadoGrafico('status-grafico-evolucao', 'Não foi possível identificar a companhia.');
    definirEstadoGrafico('status-grafico-mensal', 'Não foi possível identificar a companhia.');
    return;
  }

  fetch(`/api/graficos/operacoes/${companhiaId}`)
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
      let dadosDispersao = dados.dispersaoCapacidade;
      let dadosMensais = dados.procuraMensal;
      if (!dadosDispersao || !dadosMensais) {
        throw new Error('Dados dos gráficos não informados pela API');
      }
      if (
        !Array.isArray(dadosDispersao.mercado) ||
        !Array.isArray(dadosDispersao.companhia) ||
        !Array.isArray(dadosMensais.mediaPassageiros) ||
        !Array.isArray(dadosMensais.mediaAssentos) ||
        !Array.isArray(dadosMensais.quantidadeVoos) ||
        dadosMensais.mediaPassageiros.length !== 12 ||
        dadosMensais.mediaAssentos.length !== 12 ||
        dadosMensais.quantidadeVoos.length !== 12
      ) {
        throw new Error('Formato dos dados dos gráficos inválido');
      }

      document.getElementById('ano-grafico-evolucao').textContent = dados.anoReferencia;
      document.getElementById('ano-grafico-mensal').textContent = dados.anoReferencia;

      let pontosMercadoProcessados = processarPontosDispersao(dadosDispersao.mercado, false, 3.5);
      let pontosCompanhiaProcessados = processarPontosDispersao(dadosDispersao.companhia, true, 4.5);

      let todasCapacidades = dadosDispersao.mercado.concat(dadosDispersao.companhia).map(function (p) {
        return Number(p.x) || 0;
      }).filter(function (c) {
        return c > 0;
      });

      let minCapacidade = todasCapacidades.length > 0 ? Math.min.apply(null, todasCapacidades) : 50;
      let maxCapacidade = todasCapacidades.length > 0 ? Math.max.apply(null, todasCapacidades) : 350;
      let xInicio = Math.max(0, Math.floor(minCapacidade - 10));
      let xFim = Math.ceil(maxCapacidade + 10);

      graficoEvolucao.data.datasets[0].data = pontosMercadoProcessados;
      graficoEvolucao.data.datasets[1].data = pontosCompanhiaProcessados;
      graficoEvolucao.data.datasets[2].data = [
        { x: xInicio, y: 100 },
        { x: xFim, y: 100 }
      ];
      graficoEvolucao.data.datasets[3].data = [
        { x: xInicio, y: 75 },
        { x: xFim, y: 75 }
      ];
      graficoEvolucao.update();

      graficoMensal.data.datasets[0].data = dadosMensais.mediaPassageiros;
      graficoMensal.data.datasets[1].data = dadosMensais.mediaAssentos;
      quantidadeVoosMensais = dadosMensais.quantidadeVoos;
      graficoMensal.update();

      definirEstadoGrafico(
        'status-grafico-evolucao',
        dadosDispersao.companhia.length === 0
          ? 'Sem voos válidos da companhia no período.'
          : ''
      );
      definirEstadoGrafico(
        'status-grafico-mensal',
        dadosMensais.mediaPassageiros.every(function (valor) {
          return valor === null;
        })
          ? 'Sem voos válidos da companhia no período.'
          : ''
      );
    })
    .catch(function (erro) {
      console.error('Erro ao carregar gráficos de operações:', erro);
      definirEstadoGrafico('status-grafico-evolucao', 'Não foi possível carregar os dados.');
      definirEstadoGrafico('status-grafico-mensal', 'Não foi possível carregar os dados.');
    });
}

carregarGraficosOperacoes();
