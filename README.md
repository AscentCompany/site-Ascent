# ✈️ Ascent - Sistema de Análise e Monitoramento de Voos

Sistema completo para análise de dados de voos da ANAC, com importação automatizada, dashboards interativos e sistema de alertas parametrizados.

## 📋 Componentes do Sistema

### 1. **ascent-apachepoi** (Java)
Importador de dados ANAC usando Apache POI para ler arquivos Excel (.xlsx) e popular o banco de dados MySQL.

### 2. **ascent-api** (Node.js)
API REST e aplicação web para visualização de dashboards, configuração de alertas e gerenciamento de usuários.

### 3. **database**
Scripts SQL para criação e manutenção do banco de dados.

---

## 🚀 Setup Inicial

### Pré-requisitos
- **MySQL 8.0+** rodando em `localhost:3306`
- **Java 21** (OpenJDK recomendado)
- **Maven 3.6+**
- **Node.js 18+** e npm

### 1. Configurar Banco de Dados

```bash
# Criar banco de dados e tabelas
mysql -u root -p < database/ascent.sql

# Criar usuário dedicado (opcional mas recomendado)
mysql -u root -p
```

```sql
CREATE USER 'ascent'@'localhost' IDENTIFIED BY 'sptech';
GRANT ALL PRIVILEGES ON ascent.* TO 'ascent'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

```bash
# Validar instalação
mysql -u ascent -p ascent < database/validar-instalacao.sql
```

**📌 Dados iniciais incluídos:**
- Companhia: **Ascent Airlines** (código: **1001**)
- Usuários de teste: `camila/camila`, `gustavo/gustavo`, etc.
- Cargos e permissões configurados

### 2. Configurar Importador (ascent-apachepoi)

```bash
cd ascent-apachepoi

# Criar arquivo .env
cp .env.example .env
```

Editar `.env`:
```env
DB_HOST=localhost
DB_USER=ascent
DB_PASSWORD=sptech
DB_NAME=ascent
DB_PORT=3306
```

```bash
# Compilar
mvn clean package -DskipTests

# Importar dados locais (sem S3)
java -cp target/ascent-apachepoi-1.0-SNAPSHOT-jar-with-dependencies.jar com.ascent.apachepoi.MainAppLocal
```

**📁 Estrutura esperada dos arquivos ANAC:**
```
C:\Users\{USER}\Downloads\output\
├── anac_part_001.xlsx
├── anac_part_002.xlsx
├── ...
└── anac_part_023.xlsx
```

### 3. Configurar API Web (ascent-api)

```bash
cd ascent-api

# Instalar dependências
npm install

# Criar arquivo de ambiente
cp .env.example .env.dev
```

Editar `.env.dev`:
```env
DB_HOST=localhost
DB_USER=ascent
DB_PASSWORD=sptech
DB_NAME=ascent
DB_PORT=3306

PORT=3333
NODE_ENV=development
```

```bash
# Iniciar servidor
node app.js
```

Acesse: **http://localhost:3333**

---

## 🔧 Correções Aplicadas

### Bug Crítico Corrigido (Branch: `bugfix/corrigindo-alertas`)

**Problema:** Sistema de alertas não gerava alertas parametrizados mesmo com 120.000+ voos importados.

**Causa Raiz:** Incompatibilidade no campo `direcao` da tabela `aeroportoDirecao`:
- Importador gravava: `"Partida"` e `"Destino"`
- Queries SQL esperavam: `"ORIGEM"` e `"DESTINO"`

**Correção:**
- Arquivo: `ascent-apachepoi/src/main/java/com/ascent/apachepoi/LeitorExcel.java`
- Linhas 306 e 317 alteradas para usar `"ORIGEM"` e `"DESTINO"`

**Validação:**
```sql
-- Query que agora funciona corretamente:
SELECT 
    aOrig.direcao,
    aDest.direcao,
    ROUND((v.qtdPassageiros / av.numAssentos) * 100, 2) as ocupacao
FROM voo v
JOIN aeroportoDirecao aOrig ON aOrig.fkVoo = v.idVoo AND aOrig.direcao = 'ORIGEM'
JOIN aeroportoDirecao aDest ON aDest.fkVoo = v.idVoo AND aDest.direcao = 'DESTINO'
WHERE (v.qtdPassageiros / av.numAssentos) * 100 < 90;
-- ✅ Retorna 10+ resultados
```

### Schema do Banco Atualizado

O arquivo `database/ascent.sql` agora contém o schema correto das tabelas de alerta:

**regraAlerta:**
```sql
idRegraAlerta INT PRIMARY KEY
faixaOcupacao DECIMAL(5,2) NOT NULL
severidade VARCHAR(10) NOT NULL
janelaAnalise VARCHAR(20) NOT NULL
janelaInicio DATE NULL
janelaFim DATE NULL
ativo TINYINT(1) NOT NULL
fkCompanhia INT NOT NULL
fkUsuarioCriador INT NOT NULL
dataCriacao DATETIME DEFAULT CURRENT_TIMESTAMP
```

**Se você executou o `banco.sql` antigo:**
```bash
mysql -u ascent -p ascent < database/corrigir-schema-alertas.sql
```

---

## 📊 Funcionalidades

### Sistema de Alertas Parametrizados

1. **Configurar Regras de Alerta** (tela web)
   - Definir faixa de ocupação (ex: < 90%)
   - Escolher severidade (baixa, média, alta, crítica)
   - Configurar janela de análise (todo histórico ou período específico)

2. **Central de Alertas**
   - Visualiza alertas gerados automaticamente
   - Agrupa por rota (origem → destino)
   - Mostra ocupação média calculada

3. **Dashboards**
   - Dashboard de Rotas
   - Dashboard de Operações
   - Gráficos de ocupação

---

## 🗂️ Estrutura de Arquivos

```
site-Ascent/
├── ascent-apachepoi/           # Importador Java
│   ├── src/main/java/com/ascent/apachepoi/
│   │   ├── LeitorExcel.java    # ✅ Corrigido (ORIGEM/DESTINO)
│   │   ├── MainAppLocal.java   # Importação local sem S3
│   │   └── ...
│   ├── pom.xml
│   └── .env
│
├── ascent-api/                 # API Node.js + Frontend
│   ├── app.js
│   ├── database/config.js
│   ├── public/                 # HTML, CSS, JS do frontend
│   ├── package.json
│   └── .env.dev
│
├── database/                   # Scripts SQL
│   ├── ascent.sql             # ✅ ARQUIVO OFICIAL
│   ├── seed.sql               # Dados iniciais
│   ├── corrigir-schema-alertas.sql  # Fix para banco antigo
│   ├── validar-instalacao.sql # Verificação completa
│   ├── README.md              # Documentação dos scripts
│   └── scripts-debug/         # Scripts de diagnóstico
│
└── README.md                   # Este arquivo
```

---

## 🧪 Validação End-to-End

### 1. Validar Banco de Dados
```bash
mysql -u ascent -p ascent < database/validar-instalacao.sql
```

Deve mostrar:
- ✅ 14 tabelas criadas
- ✅ Estrutura regraAlerta correta
- ✅ Companhia 1001 criada
- ✅ 6+ usuários de teste
- ✅ 7+ permissões configuradas

### 2. Validar Importação
```bash
cd ascent-apachepoi
java -cp target/ascent-apachepoi-1.0-SNAPSHOT-jar-with-dependencies.jar com.ascent.apachepoi.MainAppLocal
```

Deve importar:
- ✅ 120.000+ voos
- ✅ 80+ companhias
- ✅ 240+ aeroportos
- ✅ Logs detalhados no banco

### 3. Validar API e Alertas
```bash
cd ascent-api
node app.js
```

No navegador (http://localhost:3333):
1. Login: `camila@ascent.com` / `camila`
2. Ir em **Configurar Alertas**
3. Clicar **Criar Regra**
4. Configurar:
   - Ocupação: **< 90%**
   - Severidade: **Alta**
   - Janela: **Todo o histórico**
5. Ir em **Central de Alertas**
6. ✅ Deve aparecer alertas com rotas reais

---

## 🐛 Troubleshooting

### Problema: "Unknown column 'faixaOcupacao'"
**Causa:** Executou `banco.sql` em vez de `ascent.sql`

**Solução:**
```bash
mysql -u ascent -p ascent < database/corrigir-schema-alertas.sql
```

### Problema: Nenhum alerta gerado
**Causa:** Dados não importados ou correção não aplicada

**Solução:**
1. Verificar se há voos: `SELECT COUNT(*) FROM voo;`
2. Verificar direcao: `SELECT DISTINCT direcao FROM aeroportoDirecao;`
   - Deve retornar: `ORIGEM`, `DESTINO`
   - Se retornar `Partida`, `Destino`: reimportar com código corrigido

### Problema: "Access denied for user 'ascent'@'localhost'"
**Solução:**
```sql
CREATE USER 'ascent'@'localhost' IDENTIFIED BY 'sptech';
GRANT ALL PRIVILEGES ON ascent.* TO 'ascent'@'localhost';
FLUSH PRIVILEGES;
```

### Problema: "Cannot find module 'dotenv'"
**Solução:**
```bash
cd ascent-api
npm install
```

---

## 📚 Documentação Adicional

- **Database:** `database/README.md` - Explicação detalhada dos scripts SQL
- **Commits relevantes:**
  - `3de1e97` - Correção LeitorExcel.java (ORIGEM/DESTINO)
  - `39eff89` - Atualização documentação

---

## 👥 Usuários de Teste

| Nome | Email | Senha | Cargo |
|------|-------|-------|-------|
| Camila | camila@ascent.com | camila | Administrador |
| Giovanna | giovanna@ascent.com | giovanna | Administrador |
| Gustavo | gustavo@ascent.com | gustavo | Gestor de Operações Aéreas |
| Lucas | lucas@ascent.com | lucas | Gestor de Operações Aéreas |
| Matheus | matheus@ascent.com | matheus | Analista de Planejamento de Rotas |
| Thamyres | thamyres@ascent.com | thamyres | Analista de Planejamento de Rotas |

---

## 📝 Licença

Este projeto foi desenvolvido como parte do curso de Ciência da Computação da SPTECH.

---

## 🤝 Contribuindo

1. Sempre use o branch `develop` como base
2. Crie branches com prefixos: `feature/`, `bugfix/`, `hotfix/`
3. Commits descritivos em português
4. Execute validações antes de commitar

---

**Desenvolvido com ☕ pela equipe Ascent**
