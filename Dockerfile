# =====================================================================
# Dockerfile Multi-Stage para Nginx com Frontend React Embutido
# =====================================================================

# --- Estágio 1: Frontend Builder ---
# Usa uma imagem Node.js para construir a aplicação React.
FROM node:18-alpine AS frontend_builder

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de manifesto do projeto e instala as dependências.
# Isso aproveita o cache do Docker, reinstalando dependências apenas se package.json mudar.
COPY ./web-dashboard/package.json ./web-dashboard/package-lock.json ./
RUN npm install

# Copia o resto do código do frontend
COPY ./web-dashboard/ ./

# Executa o build de produção, que gera os arquivos estáticos na pasta /app/build
RUN npm run build

# --- Estágio 2: Nginx Final ---
# Usa uma imagem leve do Nginx para a imagem final.
FROM nginx:alpine

# Copia os arquivos estáticos construídos no estágio anterior para o diretório padrão do Nginx.
COPY --from=frontend_builder /app/build /usr/share/nginx/html

# Copia a configuração personalizada do Nginx.
COPY ./nginx/conf.d/app.conf /etc/nginx/conf.d/default.conf