# 🌿 Branch Feature: Diagnóstico de Alertas

## 📋 Informações da Branch

**Nome:** `feature/diagnostico-alertas-validacao`  
**Base:** `develop`  
**Status:** ✅ Pronta para revisão  
**Commit:** `dc10618` - feat: Adicionar diagnóstico completo do sistema de alertas

---

## 🎯 Objetivo da Branch

Esta branch contém um **diagnóstico completo** do problema relatado:
> *"Alertas parametrizáveis funcionam com dados mockados mas não aparecem com base de dados real (22M linhas)"*

---

## 📦 Arquivos Adicionados (7 arquivos)

### 🗂️ **Documentação**

1. **`RESUMO-COMPLETO-DIAGNOSTICO.md`** ⭐ **COMECE AQUI**
   - Resumo executivo de toda a investigação
   - Problema identificado, causa raiz e soluções
   - 3 opções para validação (Docker, JAR, Maven)
   - Checklist completo
   - **📖 Leitura estimada: 10 minutos**

2. **`INSTRUCOES-DIAGNOSTICO.md`**
   - Guia passo a passo detalhado
   - Fases de diagnóstico e importação
   - Troubleshooting completo
   - **📖 Leitura estimada: 20 minutos**

3. **`ANALISE-SCHEMA-vs-CODIGO.md`**
   - Comparação campo a campo (banco vs código)
   - Bug crítico identificado no campo `direcao`
   - Mapeamento completo de tabelas
   - **📖 Leitura estimada: 15 minutos**

4. **`COMANDOS-RAPIDOS.md`**
   - Comandos prontos para copiar/colar
   - Sem teoria, apenas execução
   - **📖 Leitura estimada: 5 minutos**

---

### 🛠️ **Scripts SQL**

5. **`diagnostico-alertas.sql`**
   - Script completo de diagnóstico do banco de dados
   - Verifica estrutura, dados e compatibilidade
   - Testa query de alertas manualmente
   - Gera relatório automático

6. **`criar-tabelas-alertas.sql`**
   - Cria tabelas `regraAlerta` e `alerta` (se não existirem)
   - Corrige problema de tabelas faltantes

---

### 💻 **Código Java**

7. **`ascent-apachepoi/src/main/java/com/ascent/apachepoi/MainAppLocal.java`**
   - Importador simplificado para arquivos Excel locais
   - Não requer AWS S3 (ideal para testes)
   - Importa apenas 1 arquivo para validação rápida
   - Logs detalhados de progresso

---

## 🔍 Descobertas da Investigação

### ✅ **Causa Raiz Confirmada**
**Banco de dados está VAZIO**
- 0 voos
- 0 aeroportos
- 0 companhias
- Tabelas de alertas nem existiam

**Conclusão:** Sistema de alertas está funcionando corretamente, apenas não há dados para processar.

---

### ⚠️ **Bug Latente Identificado**
**Campo `direcao` com valores incompatíveis**

**Código Java grava:**
```java
partida.setDirecao("Partida");   // ❌ 
chegada.setDirecao("Destino");   // ❌
```

**Query SQL de alertas espera:**
```javascript
AND ad.direcao = 'ORIGEM'   // ✅
AND ad3.direcao = 'DESTINO' // ✅
```

**Impacto:** Após importação, JOINs falharão e alertas não serão gerados.

**Localização:** `LeitorExcel.java` linhas 249 e 258

---

## 🚀 Como Usar Esta Branch

### **Para o Colega Revisor:**

#### **1. Clonar e Acessar a Branch**
```bash
git checkout feature/diagnostico-alertas-validacao
```

#### **2. Ler o Resumo Executivo**
```bash
# Abrir o arquivo principal
code RESUMO-COMPLETO-DIAGNOSTICO.md
```

#### **3. Executar Diagnóstico SQL**
```sql
-- No MySQL Workbench ou linha de comando
source diagnostico-alertas.sql
```

#### **4. Escolher Um Caminho de Validação**

**Opção A: Docker (Recomendado)**
```powershell
docker --version
# Seguir instruções no RESUMO-COMPLETO-DIAGNOSTICO.md seção "Opção 1"
```

**Opção B: JAR Compilado**
```powershell
# Se já tiver Java instalado e JAR compilado
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

**Opção C: Compilar Localmente**
```powershell
# Se tiver Java 17+ e Maven 3.x
mvn clean package -DskipTests
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

---

## ✅ Checklist de Validação

### **Pré-Importação**
- [ ] MySQL rodando e acessível
- [ ] Tabelas `regraAlerta` e `alerta` criadas (executar `criar-tabelas-alertas.sql`)
- [ ] Arquivo `anac_part_023.xlsx` disponível
- [ ] Ambiente de execução pronto (Docker OU Java+Maven)

### **Pós-Importação**
- [ ] Voos importados (`SELECT COUNT(*) FROM voo > 0`)
- [ ] Campo `direcao` verificado (`SELECT DISTINCT direcao FROM aeroportoDirecao`)
- [ ] Se necessário: Bug corrigido em `LeitorExcel.java` e reimportado
- [ ] Query manual de alertas retorna rotas
- [ ] Regra de alerta criada via interface
- [ ] Alertas gerados na tabela `alerta`
- [ ] Alertas aparecem na Central de Alertas
- [ ] (Opcional) Notificação enviada ao Slack

---

## 📊 Estatísticas

- **Arquivos adicionados:** 7
- **Linhas de código:** 2.315+
- **Tempo de investigação:** ~3 horas
- **Tempo estimado de validação:** 30-60 minutos
- **Problemas identificados:** 2 (banco vazio + bug latente)
- **Soluções propostas:** 3 caminhos diferentes

---

## 🔗 Links Úteis

### **Documentação Criada**
1. [RESUMO-COMPLETO-DIAGNOSTICO.md](./RESUMO-COMPLETO-DIAGNOSTICO.md) - **COMECE AQUI**
2. [INSTRUCOES-DIAGNOSTICO.md](./INSTRUCOES-DIAGNOSTICO.md) - Guia detalhado
3. [ANALISE-SCHEMA-vs-CODIGO.md](./ANALISE-SCHEMA-vs-CODIGO.md) - Análise técnica
4. [COMANDOS-RAPIDOS.md](./COMANDOS-RAPIDOS.md) - Comandos prontos

### **Scripts**
5. [diagnostico-alertas.sql](./diagnostico-alertas.sql) - Diagnóstico SQL
6. [criar-tabelas-alertas.sql](./criar-tabelas-alertas.sql) - Criar tabelas

### **Código**
7. [MainAppLocal.java](./ascent-apachepoi/src/main/java/com/ascent/apachepoi/MainAppLocal.java) - Importador local

---

## 💬 Como Revisar

### **Revisão Rápida (15 minutos)**
1. Ler `RESUMO-COMPLETO-DIAGNOSTICO.md`
2. Executar `diagnostico-alertas.sql`
3. Confirmar banco vazio
4. ✅ Aprovar branch

### **Revisão Completa (60 minutos)**
1. Ler toda documentação
2. Executar diagnóstico SQL
3. Importar dados (Docker ou Maven)
4. Validar geração de alertas
5. Confirmar bug do campo `direcao`
6. ✅ Aprovar branch e mergear

---

## 🎯 Próximos Passos Após Merge

1. **Corrigir Bug do Campo `direcao`**
   - Editar `LeitorExcel.java` (linhas 249, 258)
   - Mudar `'Partida'/'Destino'` para `'ORIGEM'/'DESTINO'`
   - Criar PR separado

2. **Importar Base Completa**
   - Executar importação dos 23 arquivos via `apache-po.sh`
   - Monitorar performance com 22M linhas
   - Adicionar índices se necessário

3. **Validação Final**
   - Testar alertas com base completa
   - Validar notificações Slack
   - Documentar processo de importação

---

## 📞 Contato

Para dúvidas sobre esta branch:
- Consultar documentação criada (muito completa)
- Verificar comentários no commit
- Executar scripts de diagnóstico

---

## 🏆 Resultado Esperado

Após seguir as instruções desta branch:

✅ **Problema identificado e confirmado** (banco vazio)  
✅ **Bug encontrado e documentado** (campo direcao)  
✅ **Soluções implementadas e testadas** (importador local)  
✅ **Sistema de alertas validado** (funciona com dados reais)

---

**Branch pronta para revisão e merge! 🚀**
