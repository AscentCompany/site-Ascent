# Instruções de Diagnóstico - Sistema de Alertas Ascent

## 📋 Objetivo

Validar se o sistema de alertas parametrizáveis funciona com a base de dados real, testando com apenas 1 arquivo Excel (`anac_part_023.xlsx`) para diagnóstico rápido.

---

## 🔍 Fase 1: Diagnóstico do Banco de Dados (5-10 min)

### Passo 1.1: Conectar ao MySQL

Você precisa ter acesso ao MySQL localmente. Existem várias formas:

**Opção A: Via MySQL Workbench (Interface Gráfica)**
1. Abra o MySQL Workbench
2. Conecte-se usando as credenciais do `.env`:
   - Host: `localhost` (ou o valor de `DB_HOST`)
   - Port: `3306` (ou o valor de `DB_PORT`)
   - User: valor de `DB_USER`
   - Password: valor de `DB_PASSWORD`
   - Database: valor de `DB_DATABASE` (provavelmente `ascent`)

**Opção B: Via Linha de Comando**
```bash
mysql -h localhost -u [DB_USER] -p[DB_PASSWORD] [DB_DATABASE]
```

**Opção C: Via Docker (se o banco está em container)**
```bash
docker exec -it ascent-mysql mysql -u [DB_USER] -p[DB_PASSWORD] [DB_DATABASE]
```

### Passo 1.2: Executar Script de Diagnóstico

No MySQL Workbench ou linha de comando, execute:

```sql
source C:/Users/Pichau/Downloads/site-Ascent/diagnostico-alertas.sql
```

Ou copie e cole o conteúdo do arquivo no MySQL Workbench e execute.

### Passo 1.3: Analisar Resultados

O script irá mostrar:

1. **Estrutura das Tabelas** - Verificar se corresponde ao esperado pelo código
2. **Contagem de Registros** - Ver se há dados no banco
3. **Voos por Companhia** - Identificar qual `idCompanhia` tem dados
4. **Dados de Ocupação** - Verificar se há `qtdPassageiros` e `numAssentos` preenchidos
5. **Regras de Alerta** - Ver se você criou regras para as companhias corretas
6. **Alertas Gerados** - Ver se há alertas na tabela
7. **Amostra de Voos** - Ver exemplos de dados importados
8. **Simulação da Query** - Testar a query que busca rotas com ocupação baixa
9. **Logs de Importação** - Ver se já houve tentativas anteriores

**📊 Interpretação dos Resultados:**

| Cenário | O que fazer |
|---------|-------------|
| `total_voos = 0` | ✅ **Prosseguir para Fase 2** - Precisa importar dados |
| `total_voos > 0` mas `fkCompanhia != 1 ou 2` | ⚠️ **Ajustar testes** - Usar o `idCompanhia` correto |
| `total_voos > 0` para companhia 1/2 mas nenhum alerta | ⚠️ **Investigar query** - Pode ter problema na lógica |
| `alertas > 0` | ✅ **Sistema funcionando!** - Verificar por que não aparecem na interface |

---

## 🔧 Fase 2: Importação Local do Arquivo de Teste (30-60 min)

**⚠️ Execute esta fase APENAS se o diagnóstico mostrou que não há voos no banco.**

### Passo 2.1: Verificar Pré-requisitos

1. ✅ Java 17 ou superior instalado
2. ✅ Maven instalado
3. ✅ MySQL rodando e acessível localmente
4. ✅ Arquivo `anac_part_023.xlsx` em `C:\Users\Pichau\Downloads\output\`
5. ✅ Arquivo `.env` configurado na raiz do projeto

### Passo 2.2: Configurar .env para Conexão Local

Crie ou edite o arquivo `.env` na raiz do projeto `site-Ascent`:

```env
# Conexão com o banco de dados (local)
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=ascent
DB_USER=root
DB_PASSWORD=sua_senha_aqui

# Caminho do arquivo para importação local (opcional)
ARQUIVO_LOCAL=C:\Users\Pichau\Downloads\output\anac_part_023.xlsx

# Ambiente
AMBIENTE_PROCESSO=desenvolvimento
```

**💡 Dica:** Se o MySQL está rodando em Docker, pode ser necessário usar um port mapping. Verifique com:
```bash
docker ps --filter "name=mysql"
```

### Passo 2.3: Compilar o Projeto

Abra o terminal no diretório `ascent-apachepoi`:

```bash
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-apachepoi
mvn clean package -DskipTests
```

Aguarde a compilação (pode demorar alguns minutos na primeira vez).

### Passo 2.4: Executar a Importação

```bash
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

**📊 O que esperar:**

- O processo irá ler o arquivo Excel linha por linha
- A cada 5.000 linhas, será feito um commit no banco
- Logs detalhados serão exibidos no console
- Pode demorar de 5 a 20 minutos dependendo do hardware

**Exemplo de saída:**
```
[14:23:45] ╔══════════════════════════════════════════════╗
[14:23:45] ║   Ascent — Importação Local (Diagnóstico)    ║
[14:23:45] ╚══════════════════════════════════════════════╝
[14:23:45] [Conexao] MySQL: jdbc:mysql://localhost:3306/ascent
[14:23:45] Arquivo: C:\Users\Pichau\Downloads\output\anac_part_023.xlsx
[14:23:45] Tamanho: 61.4 MB
[14:23:45] ────────────────────────────────────────────────
[14:23:45] Iniciando leitura e inserção no banco de dados...
[14:23:45] Aguarde... Este processo pode demorar alguns minutos.
...
[14:28:12] ────────────────────────────────────────────────
[14:28:12] Leitura concluída:
[14:28:12]   • Linhas encontradas: 1,000,000
[14:28:12]   • Linhas válidas (lidas): 985,432
[14:28:12]   • Linhas rejeitadas: 14,568
[14:28:12]   • Status: PARCIALMENTE_LIDO
[14:28:12] ────────────────────────────────────────────────
[14:28:12] Dados inseridos no banco:
[14:28:12]   • Companhias distintas: 12
[14:28:12]   • Aviões distintos: 87
[14:28:12]   • Aeroportos distintos: 234
[14:28:12]   • Voos inseridos: 985,432
[14:28:12]   • Direções inseridas: 1,970,864
[14:28:12] ╔══════════════════════════════════════════════╗
[14:28:12] ║      ✅ Importação concluída com sucesso      ║
[14:28:12] ╚══════════════════════════════════════════════╝
```

### Passo 2.5: Validar Importação

Execute novamente o script de diagnóstico (Fase 1) para verificar:

```sql
-- Ver quantos voos foram importados
SELECT COUNT(*) FROM voo;

-- Ver distribuição por companhia
SELECT fkCompanhia, COUNT(*) as total 
FROM voo 
GROUP BY fkCompanhia;

-- Ver amostra de dados
SELECT v.*, c.nomeCompanhia 
FROM voo v 
LEFT JOIN companhia c ON c.idCompanhia = v.fkCompanhia 
LIMIT 10;
```

---

## 🎯 Fase 3: Testar Geração de Alertas (10-15 min)

### Passo 3.1: Adicionar Logs Detalhados no Backend (Opcional)

Para ter mais visibilidade do processamento, edite o arquivo:
`ascent-api/src/models/alertaModel.js`

Na função `processarRegra()`, adicione logs:

```javascript
function processarRegra(idRegra, idCompanhia) {
    console.log("====================================");
    console.log("PROCESSANDO REGRA DE ALERTA");
    console.log("idRegra:", idRegra);
    console.log("idCompanhia:", idCompanhia);
    console.log("====================================");
    
    return database.executar(`SELECT * FROM regraAlerta WHERE idRegraAlerta = ${idRegra} AND fkCompanhia = ${idCompanhia} LIMIT 1;`)
        .then(function (rows) {
            console.log("Regra encontrada:", rows);
            
            if (!rows.length || !rows[0].ativo) {
                console.log("Regra não encontrada ou inativa. Abortando.");
                return;
            }

            let r = rows[0];
            let filtroData = "";

            // ... resto do código ...
            
            console.log("Executando query de busca de rotas...");
            console.log("Filtro temporal:", filtroData);
            console.log("Faixa de ocupação:", r.faixaOcupacao);

            return database.executar(/* query SQL */)
                .then(function (rotas) {
                    console.log("====================================");
                    console.log("ROTAS ENCONTRADAS:", rotas.length);
                    console.log("====================================");
                    
                    if (rotas.length > 0) {
                        console.log("Primeiras 5 rotas:");
                        console.log(rotas.slice(0, 5));
                    }
                    
                    // ... resto do código ...
                });
        });
}
```

Reinicie o servidor Node.js:
```bash
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-api
npm start
```

### Passo 3.2: Criar Regra de Alerta

1. Acesse a interface: `http://localhost:3333/dashboard/configurarAlertas.html`
2. Clique em "Criar Regra"
3. Configure:
   - **Faixa de ocupação:** `90%` (bem permissiva para capturar várias rotas)
   - **Severidade:** `Atenção` (🟡)
   - **Janela:** `Todo o histórico`
   - **Status:** `Ativa` ✅
4. Clique em "Salvar Regra"

### Passo 3.3: Verificar Processamento

**A: Verificar no Console do Node.js**

Você deve ver os logs de processamento que adicionamos:
```
====================================
PROCESSANDO REGRA DE ALERTA
idRegra: 1
idCompanhia: 1
====================================
Regra encontrada: [ { idRegraAlerta: 1, faixaOcupacao: 90, ... } ]
Executando query de busca de rotas...
Filtro temporal: 
Faixa de ocupação: 90
====================================
ROTAS ENCONTRADAS: 15
====================================
```

**B: Verificar no Banco de Dados**

```sql
-- Ver alertas gerados
SELECT * FROM alerta WHERE fkCompanhia = 1 ORDER BY dataCriacao DESC;

-- Ver detalhes
SELECT 
    a.origemIata,
    a.destinoIata,
    a.ocupacaoMedia,
    a.severidade,
    r.faixaOcupacao
FROM alerta a
JOIN regraAlerta r ON r.idRegraAlerta = a.fkRegraAlerta
WHERE a.fkCompanhia = 1;
```

**C: Verificar na Interface**

1. Acesse: `http://localhost:3333/dashboard/centralAlertas.html`
2. Você deve ver os alertas listados
3. Clique em um alerta para ver detalhes

### Passo 3.4: Verificar Notificação Slack (Opcional)

Se o `NotificadorApp` (ascent-logs) estiver rodando:

```bash
# Ver logs do container
docker logs ascent-logs

# Ou se estiver rodando local
# Verificar console Java
```

Deve aparecer:
```
Notificação disparada para o Slack!
```

E no canal Slack configurado, deve aparecer a mensagem:
```
🟡 [ATENÇÃO] Alerta Ascent: Rota SP → RJ com 65.5% de ocupação (abaixo de 90%)
```

---

## 🐛 Problemas Comuns e Soluções

### Problema 1: "Connection refused" ao conectar no MySQL

**Causa:** Banco não está rodando ou está em Docker

**Solução:**
```bash
# Verificar se MySQL está rodando
docker ps --filter "name=mysql"

# Se estiver em Docker, usar host "mysql" ou mapear porta
# Ajustar DB_HOST no .env conforme ambiente
```

### Problema 2: Importação muito lenta

**Causa:** Arquivo grande, hardware limitado, ou índices do banco

**Solução:**
- Aguardar pacientemente (pode demorar 10-20 min)
- Verificar se há espaço em disco suficiente
- Monitorar uso de CPU/memória

### Problema 3: Query de alertas retorna 0 rotas

**Causa:** Dados não correspondem aos filtros, ou problema no JOIN

**Solução:**
1. Verificar se a coluna `direcao` está como `'ORIGEM'` e `'DESTINO'` (maiúsculas)
   ```sql
   SELECT DISTINCT direcao FROM aeroportoDirecao;
   ```

2. Se estiver como `'Partida'` e `'Destino'`, o problema está no mapeamento!
   
   **Corrigir em `LeitorExcel.java` linha ~249:**
   ```java
   partida.setDirecao("ORIGEM");  // era "Partida"
   ```
   
   **E linha ~258:**
   ```java
   chegada.setDirecao("DESTINO");  // era "Destino"
   ```

3. Recompilar e reimportar

### Problema 4: Regra criada mas não processa

**Causa:** Função `processarRegra()` não está sendo chamada

**Solução:**
1. Verificar se a rota POST está correta em `alertaController.js`
2. Adicionar logs para debug
3. Verificar se há erros no console do Node.js

### Problema 5: Alertas gerados mas não aparecem na interface

**Causa:** Problema no frontend ou `idCompanhia` errado

**Solução:**
1. Abrir DevTools do navegador (F12)
2. Ver aba Console para erros JavaScript
3. Ver aba Network para verificar requisições
4. Verificar se `sessionStorage.COMPANHIA_USUARIO` está correto

---

## 📊 Comparação: Schema do Banco vs Código

### Tabela: `voo`

| Campo BD | Tipo BD | Campo Código | Tipo Código | Match | Notas |
|----------|---------|--------------|-------------|-------|-------|
| idVoo | INT | idVoo | Integer | ✅ | PK auto_increment |
| numVoo | INT | numVoo | Integer | ✅ | Número do voo |
| tipoVoo | INT | tipoVoo | Integer | ✅ | Código DI |
| qtdPassageiros | INT | qtdPassageiros | Integer | ✅ | **CRÍTICO para alertas** |
| fkCompanhia | INT | fkCompanhia | Integer | ✅ | FK para companhia |
| fkAviao | INT | fkAviao | Integer | ✅ | FK para aviao |

### Tabela: `aeroportoDirecao`

| Campo BD | Tipo BD | Campo Código | Tipo Código | Match | Notas |
|----------|---------|--------------|-------------|-------|-------|
| fkAeroporto | INT | fkAeroporto | Integer | ✅ | FK |
| fkVoo | INT | (via id gerado) | Integer | ✅ | FK |
| **direcao** | VARCHAR | direcao | String | ⚠️ | **VERIFICAR VALORES** |
| dia | DATE | dia | LocalDate | ✅ | Data do voo |
| hora | TIME | hora | LocalTime | ✅ | Hora do voo |

**⚠️ ATENÇÃO - Campo `direcao`:**

A query de alertas espera:
- `'ORIGEM'` (maiúscula)
- `'DESTINO'` (maiúscula)

Mas o código `LeitorExcel.java` está gravando:
- `'Partida'` (linha 249)
- `'Destino'` (linha 258)

**Isso causa incompatibilidade!** A query não encontra rotas porque o JOIN falha.

### Tabela: `aviao`

| Campo BD | Tipo BD | Campo Código | Tipo Código | Match | Notas |
|----------|---------|--------------|-------------|-------|-------|
| idAviao | INT | idAviao | Integer | ✅ | PK |
| **numAssentos** | INT | numAssentos | Integer | ✅ | **CRÍTICO para alertas** |
| modelo | VARCHAR | modelo | String | ✅ | Modelo da aeronave |

### Tabela: `regraAlerta`

| Campo BD | Tipo BD | Campo JS | Match | Notas |
|----------|---------|----------|-------|-------|
| idRegraAlerta | INT | idRegra | ✅ | PK |
| faixaOcupacao | DECIMAL(5,2) | faixaOcupacao | ✅ | Limite de alerta |
| severidade | VARCHAR(10) | severidade | ✅ | 'critico' ou 'atencao' |
| janelaAnalise | VARCHAR(20) | janelaAnalise | ✅ | '1_ano', '3_anos', etc |
| janelaInicio | DATE | janelaInicio | ✅ | NULL se não for personalizado |
| janelaFim | DATE | janelaFim | ✅ | NULL se não for personalizado |
| ativo | TINYINT(1) | ativo | ✅ | 0 ou 1 |
| fkCompanhia | INT | idCompanhia | ✅ | FK |

---

## ✅ Checklist de Validação Final

Antes de considerar o problema resolvido:

- [ ] Script de diagnóstico executado
- [ ] Contagem de voos > 0 no banco
- [ ] Campo `direcao` está com valores corretos ('ORIGEM' e 'DESTINO')
- [ ] Há dados de `qtdPassageiros` e `numAssentos` preenchidos
- [ ] Regra de alerta criada com sucesso
- [ ] Query manual retorna rotas com ocupação baixa
- [ ] Alertas inseridos na tabela `alerta`
- [ ] Alertas aparecem na Central de Alertas (interface)
- [ ] (Opcional) Notificação enviada ao Slack

---

## 🎓 Aprendizados e Próximos Passos

Após validar com 1 arquivo:

1. **Se funcionou:** Importar os 23 arquivos completos via `apache-po.sh` (AWS S3)
2. **Se não funcionou:** Usar este diagnóstico para identificar o problema exato
3. **Otimizações futuras:**
   - Adicionar índices nas colunas usadas nos JOINs
   - Cache de regras ativas para evitar reprocessamento
   - Processamento assíncrono de alertas (queue)
   - Webhook para notificações em tempo real

---

## 📞 Suporte

Se encontrar problemas não documentados aqui:

1. Verificar logs detalhados (Node.js console + Java console)
2. Executar queries SQL manualmente para isolar o problema
3. Validar que o schema do banco está atualizado (`database/ascent.sql`)
4. Verificar permissões de usuário no MySQL

**Boa sorte com o diagnóstico! 🚀**
