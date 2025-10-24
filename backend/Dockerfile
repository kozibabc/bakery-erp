FROM node:18-alpine

RUN apk add --no-cache python3 make g++ postgresql-client wget

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
