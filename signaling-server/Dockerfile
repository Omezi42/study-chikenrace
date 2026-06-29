FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Cloud providers usually pass the port via the PORT environment variable
ENV PORT=7860
EXPOSE 7860

CMD ["npm", "start"]
