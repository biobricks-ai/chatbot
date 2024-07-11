FROM mongo:latest as mongo-chatui

WORKDIR /app/chat-ui

RUN mkdir -p /data/db

ARG MONGODB_URL=mongodb://127.0.0.1:27017

EXPOSE 27017
