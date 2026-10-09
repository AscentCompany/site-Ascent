# Imagem base do container
FROM node:18-alpine

# Acessa a pasta /app (Caso não exista, será criada)
WORKDIR /app

#Copia o packet.json e o packet-lock.json para dentro do container para rodar o npm
COPY package*.json ./

#Instala o npm no container
RUN npm install

#Copia os arquivos para dentro do container
COPY . .

#Documentação Base para saber em qual porta está rodando
EXPOSE 3333

#Roda a api assim que ele termina os processos
CMD ["npm", "start"]

#Copiar imagem:
#docker pull lucasveneroso/ascent:ascent-api

#Como rodar:
#docker run -d -p 3333:3333 --name ascent-api  ascent-api:latest 