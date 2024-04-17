FROM node:18-alpine as development
ARG WS_URL=ws://localhost:4000
ENV VITE_WS_URL=$WS_URL

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . ./

RUN npm run build

FROM nginx:1.25.2-alpine as production

EXPOSE 80

COPY --from=development /app/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=development /app/dist /usr/share/nginx/html

# COPY --from=development /app/env.sh /docker-entrypoint.d/env.sh
# RUN chmod +x /docker-entrypoint.d/env.sh

CMD ["nginx", "-g", "daemon off;"]