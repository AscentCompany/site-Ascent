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
    nomeRota.title = rota.rota;

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

const graficoEvolucao = new Chart(document.getElementById('grafico-evolucao'), {
  type: 'scatter',
  data: {
    datasets: [
      {
        label: 'Mercado (todas as companhias)',
        data: [],
        backgroundColor: 'rgba(181, 181, 181, 0.2)',
        borderColor: 'rgba(181, 181, 181, 0.3)',
        pointRadius: 1.5,
        pointHoverRadius: 3
      },
      {
        label: 'Sua companhia',
        data: [],
        backgroundColor: '#ff6a00',
        borderColor: '#ff6a00',
        pointRadius: 4,
        pointHoverRadius: 6
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
          boxWidth: 12,
          boxHeight: 12,
          usePointStyle: true,
          pointStyle: 'circle',
          font: { size: 11 },
          color: '#555'
        }
      },
      tooltip: {
        callbacks: {
          label: function (contexto) {
            let ponto = contexto.raw;
            let quantidadeVoos = Number(ponto.quantidadeVoos) || 0;
            let vooLabel = quantidadeVoos === 1 ? 'voo' : 'voos';
            return ` ${contexto.dataset.label}: ${ponto.y} passageiros / ${ponto.x} assentos (${quantidadeVoos} ${vooLabel})`;
          }
        }
      }
    },
    scales: {
      x: {
        type: 'linear',
        beginAtZero: true,
        grid: { display: false },
        border: { display: false },
        ticks: {
          maxTicksLimit: 5,
          color: '#777',
          font: { size: 10 }
        },
        title: {
          display: true,
          text: 'Capacidade do Avião',
          color: '#555',
          font: { size: 10, weight: '600' }
        }
      },
      y: {
        beginAtZero: true,
        grid: { color: '#ececec' },
        border: { display: false },
        ticks: {
          maxTicksLimit: 5,
          color: '#777',
          font: { size: 10 }
        },
        title: {
          display: true,
          text: 'Nº de Passageiros',
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

      graficoEvolucao.data.datasets[0].data = dadosDispersao.mercado;
      graficoEvolucao.data.datasets[1].data = dadosDispersao.companhia;
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
