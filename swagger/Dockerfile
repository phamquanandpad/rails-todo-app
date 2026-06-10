FROM node:20-slim
WORKDIR /swagger
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
CMD ["npm", "run", "watch"]
