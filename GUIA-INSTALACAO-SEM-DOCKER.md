# 🛠️ Guia de Instalação - Validação Sem Docker

## 🎯 Objetivo

Este guia mostra como validar o sistema de alertas **SEM usar Docker**, instalando as ferramentas necessárias (Java e Maven) ou usando alternativas.

---

## ⚡ **Opção 1: Instalação Rápida via Winget (RECOMENDADO)**

O Windows 11/10 já vem com `winget` (gerenciador de pacotes oficial da Microsoft).

### **Passo 1: Instalar Java 17**

```powershell
# Abrir PowerShell como Administrador (Win + X → Terminal Admin)

# Instalar Java 17 (OpenJDK)
winget install Microsoft.OpenJDK.17

# Fechar e reabrir PowerShell

# Verificar instalação
java -version
```

**Resultado esperado:**
```
openjdk version "17.0.x"
```

---

### **Passo 2: Instalar Maven**

```powershell
# Ainda como Admin no PowerShell

# Instalar Maven
winget install Apache.Maven

# Fechar e reabrir PowerShell

# Verificar instalação
mvn -version
```

**Resultado esperado:**
```
Apache Maven 3.x.x
Java version: 17.0.x
```

---

### **Passo 3: Compilar o Projeto**

```powershell
# Navegar para o diretório do importador
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-apachepoi

# Compilar (primeira vez demora ~5 minutos)
mvn clean package -DskipTests

# Verificar se JAR foi criado
Test-Path ".\target\ascent-apachepoi-1.0.jar"
```

**Se retornar `True`:** ✅ Sucesso! Pode executar a importação.

---

### **Passo 4: Executar Importação**

```powershell
# Ainda no diretório ascent-apachepoi

# Executar importação do arquivo Excel
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

**Tempo estimado:** 5-20 minutos (depende do tamanho do arquivo e hardware)

---

## 📦 **Opção 2: Instalação Manual (Se Winget Não Funcionar)**

### **Passo 1: Baixar e Instalar Java 17**

1. **Download:**
   - Acesse: https://adoptium.net/temurin/releases/
   - Escolha:
     - **Version:** 17 (LTS)
     - **Operating System:** Windows
     - **Architecture:** x64
     - **Package Type:** JDK
   - Baixar o arquivo `.msi`

2. **Instalar:**
   - Executar o instalador baixado
   - Aceitar todas as opções padrão
   - ✅ Marcar "Add to PATH" (se houver opção)
   - Concluir instalação

3. **Verificar:**
   ```powershell
   # Fechar e reabrir PowerShell
   java -version
   ```

4. **Se não aparecer no PATH:**
   ```powershell
   # Adicionar Java ao PATH manualmente
   $javaPath = "C:\Program Files\Eclipse Adoptium\jdk-17.0.9.9-hotspot\bin"
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$javaPath", "Machine")
   
   # Fechar e reabrir PowerShell
   java -version
   ```

---

### **Passo 2: Baixar e Instalar Maven**

1. **Download:**
   - Acesse: https://maven.apache.org/download.cgi
   - Baixar: `apache-maven-3.9.9-bin.zip` (Binary zip archive)

2. **Extrair:**
   ```powershell
   # Criar pasta
   New-Item -ItemType Directory -Force -Path "C:\Maven"
   
   # Extrair o arquivo baixado para C:\Maven
   # (Use Windows Explorer: botão direito → Extrair tudo)
   # Resultado esperado: C:\Maven\apache-maven-3.9.9\
   ```

3. **Adicionar ao PATH:**
   ```powershell
   # Abrir PowerShell como Admin
   $mavenPath = "C:\Maven\apache-maven-3.9.9\bin"
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$mavenPath", "Machine")
   
   # Fechar e reabrir PowerShell
   mvn -version
   ```

---

### **Passo 3: Compilar e Executar**

Mesmo processo da Opção 1, Passos 3 e 4.

---

## 🎓 **Opção 3: Usar IDE (IntelliJ IDEA Community - GRATUITO)**

Se você tem ou pode instalar uma IDE Java:

### **Instalar IntelliJ IDEA Community**

```powershell
# Via Winget
winget install JetBrains.IntelliJIDEA.Community

# Ou baixar manualmente de:
# https://www.jetbrains.com/idea/download/
```

### **Importar e Executar o Projeto**

1. **Abrir IntelliJ IDEA**
2. **Open Project** → Selecionar pasta `site-Ascent/ascent-apachepoi`
3. Aguardar IDE baixar dependências (primeira vez demora)
4. **Botão direito em `MainAppLocal.java`** → Run 'MainAppLocal.main()'

**Vantagens:**
- ✅ IDE gerencia Java e Maven automaticamente
- ✅ Mais fácil para debug
- ✅ Recompila automaticamente

---

## 👥 **Opção 4: Pedir JAR Compilado Para Colega**

Se outro membro da equipe já compilou o projeto:

### **Solicitar Arquivo:**
```
Preciso do arquivo compilado:
ascent-apachepoi/target/ascent-apachepoi-1.0.jar
```

### **Executar:**
```powershell
# Apenas Java é necessário (não precisa Maven)

# Copiar JAR para qualquer pasta
# Executar:
java -cp ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

**Tempo de setup:** 2 minutos (apenas instalar Java)

---

## 🚨 **Problemas Comuns e Soluções**

### **Problema 1: "java não é reconhecido"**

**Causa:** Java não está no PATH

**Solução:**
```powershell
# Encontrar instalação do Java
Get-ChildItem "C:\Program Files" -Filter "jdk*" -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object FullName

# Adicionar ao PATH (ajuste o caminho conforme resultado acima)
$javaPath = "C:\Program Files\[caminho encontrado]\bin"
$env:Path += ";$javaPath"

# Verificar
java -version
```

---

### **Problema 2: "mvn não é reconhecido"**

**Causa:** Maven não está no PATH

**Solução:**
```powershell
# Verificar se Maven foi extraído
Test-Path "C:\Maven\apache-maven-3.9.9\bin\mvn.cmd"

# Se retornar False, extrair novamente
# Se retornar True, adicionar ao PATH:
$env:Path += ";C:\Maven\apache-maven-3.9.9\bin"
mvn -version
```

---

### **Problema 3: "Connection refused" ao conectar no MySQL**

**Causa:** MySQL não está rodando

**Soluções:**

**A) Se MySQL foi instalado como serviço Windows:**
```powershell
# Verificar status
Get-Service -Name MySQL*

# Iniciar se parado
Start-Service -Name MySQL80  # Ajuste o nome conforme resultado acima
```

**B) Se MySQL está em Docker mas você não tem Docker:**
- Instalar MySQL localmente: https://dev.mysql.com/downloads/mysql/
- Ou pedir para colega com Docker exportar o banco
- Ou usar Docker Desktop (instalação simples): https://www.docker.com/products/docker-desktop/

---

### **Problema 4: "OutOfMemoryError"**

**Causa:** Arquivo Excel muito grande

**Solução:**
```powershell
# Aumentar memória heap do Java
java -Xmx2G -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

---

## 📊 **Comparação de Opções**

| Opção | Tempo Setup | Pré-requisitos | Dificuldade | Recomendado Para |
|-------|-------------|----------------|-------------|------------------|
| **1. Winget** | 10 min | Windows 10/11 | ⭐ Fácil | Primeira escolha |
| **2. Manual** | 20 min | Nenhum | ⭐⭐ Médio | Se Winget não funcionar |
| **3. IntelliJ** | 15 min | ~2GB espaço | ⭐ Fácil | Se vai desenvolver mais |
| **4. JAR Pronto** | 2 min | Colega com ambiente | ⭐ Muito Fácil | Validação rápida |

---

## ✅ **Checklist de Instalação**

### **Pré-Requisitos**
- [ ] Windows 10 ou 11
- [ ] Conexão com internet
- [ ] PowerShell como Administrador
- [ ] ~500MB espaço em disco (Java + Maven)

### **Pós-Instalação**
- [ ] `java -version` funciona
- [ ] `mvn -version` funciona
- [ ] Projeto compila sem erros
- [ ] JAR foi criado em `target/`
- [ ] MySQL está rodando

---

## 🎯 **Recomendação Final**

Para validação do sistema de alertas **sem Docker**:

### **Caminho Mais Rápido:**
1. ✅ Instalar Java 17 via Winget (2 min)
2. ✅ Pedir JAR compilado para colega (1 min)
3. ✅ Executar importação (20 min)
4. ✅ Validar alertas (10 min)

**Tempo total:** ~35 minutos

### **Caminho Mais Completo:**
1. ✅ Instalar Java 17 via Winget (2 min)
2. ✅ Instalar Maven via Winget (2 min)
3. ✅ Compilar projeto (5 min)
4. ✅ Executar importação (20 min)
5. ✅ Validar alertas (10 min)

**Tempo total:** ~40 minutos

---

## 📞 **Suporte Adicional**

Se encontrar problemas não documentados aqui:

1. Verificar se versões estão corretas:
   ```powershell
   java -version  # Deve ser 17.x
   mvn -version   # Deve ser 3.x
   ```

2. Verificar se PATH está correto:
   ```powershell
   $env:Path -split ';' | Select-String -Pattern 'java|maven'
   ```

3. Reiniciar PowerShell após cada instalação

4. Se nada funcionar: considerar instalar Docker Desktop (solução mais robusta)

---

## 🐳 **Nota sobre Docker Desktop**

Se quiser instalar Docker para facilitar no futuro:

```powershell
# Via Winget (Windows 10/11 Pro, Enterprise ou Education)
winget install Docker.DockerDesktop

# Ou baixar instalador:
# https://www.docker.com/products/docker-desktop/
```

**Vantagens:**
- ✅ Ambiente isolado e controlado
- ✅ Mesmo ambiente usado em produção
- ✅ Não precisa instalar Java/Maven
- ✅ Facilita trabalho com banco de dados

**Desvantagens:**
- ⚠️ Requer ~2GB download
- ⚠️ Requer Windows 10/11 Pro (para WSL2) OU Home com WSL2
- ⚠️ Consome mais recursos

---

**Escolha a opção que melhor se adequa ao seu ambiente e necessidade! 🚀**
