# Imagem base do container
FROM node:18-alpine

# Acessa a pasta /app (Caso não exista, será criada)
WORKDIR /app

# Copia o package.json e o package-lock.json para dentro do container
COPY package*.json ./

# Instala as dependências
RUN npm install

# Copia os arquivos para dentro do container
COPY . .

# Documentação Base para saber em qual porta está rodando
EXPOSE 3333

# Roda a api assim que termina os processos
CMD ["npm", "start"]

# Copiar imagem:
#   docker pull lucasveneroso/ascent:ascent-api
# Como rodar:
#   docker run -d -p 3333:3333 --name ascent-api --network ascent ascent-api:latest
