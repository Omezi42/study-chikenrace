FROM node:18

# Choreo requires a non-root user with UID > 10000
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
# 権限変更
RUN chown -R choreo:choreo /app

# 非特権ユーザーに切り替え
USER 10014

# Cloud providers usually pass the port via the PORT environment variable
ENV PORT=7860
EXPOSE 7860

CMD ["npm", "start"]
