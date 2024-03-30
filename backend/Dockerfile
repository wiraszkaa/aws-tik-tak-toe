FROM node:18-alpine as development

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . ./

RUN npm run build

FROM node:18-alpine as production

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=development /app/dist ./dist

CMD ["node", "dist/index.js"]