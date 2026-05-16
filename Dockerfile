### STAGE 1: Build ###

# Image Node.js pour builder le projet
FROM node:12.7-alpine AS build

# Répertoire de travail
WORKDIR /usr/src/app

# Copier les fichiers de dépendances
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm install

# Copier tout le projet
COPY . .

# Builder l'application
RUN npm run build


### STAGE 2: Run ###

# Image Nginx
FROM nginx:1.17.1-alpine

# Copier la configuration nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copier l'application buildée depuis le stage "build"
COPY --from=build /usr/src/app/dist/aston-villa-app /usr/share/nginx/html