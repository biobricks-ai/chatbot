ARG MODEL_NAME
ARG MODEL_PARAMS
ARG MODEL_PROMPT_TEMPLATE
ARG APP_COLOR=green
ARG APP_NAME=BiobricksChat

FROM node:20 as chatui-builder
ARG MODEL_NAME
ARG MODEL_PARAMS
ARG APP_COLOR
ARG APP_NAME
ARG MODEL_PROMPT_TEMPLATE

WORKDIR /app

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git gettext && \
    rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/huggingface/chat-ui.git

WORKDIR /app/chat-ui


COPY .env.local .env.local

RUN mkdir defaults
ADD defaults /defaults
RUN chmod -R 777 /defaults
RUN --mount=type=secret,id=MONGODB_URL,mode=0444 \
    MODEL_NAME="${MODEL_NAME:="$(cat /defaults/MODEL_NAME)"}" && export MODEL_NAME \
    && MODEL_PARAMS="${MODEL_PARAMS:="$(cat /defaults/MODEL_PARAMS)"}" && export MODEL_PARAMS \
    && MODEL_PROMPT_TEMPLATE="${MODEL_PROMPT_TEMPLATE:="$(cat /defaults/MODEL_PROMPT_TEMPLATE)"}" && export MODEL_PROMPT_TEMPLATE \
    && APP_COLOR="${APP_COLOR:="$APP_COLOR"}" && export APP_COLOR \
    && APP_NAME="${APP_NAME:="$APP_NAME"}" && export APP_NAME \
    && envsubst < ".env.local" > ".env.local" \ 
    && rm .env.local

RUN --mount=type=cache,target=/app/.npm \
    npm set cache /app/.npm && \
    npm ci

RUN npm run build

FROM ghcr.io/huggingface/text-generation-inference:latest

ARG MODEL_NAME
ARG MODEL_PARAMS
ARG MODEL_PROMPT_TEMPLATE
ARG APP_COLOR
ARG APP_NAME

ENV TZ=America/New_York \
    PORT=3000



RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    gnupg \
    curl \
    gettext && \
    rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh entrypoint.sh

RUN mkdir defaults
ADD defaults /defaults
RUN chmod -R 777 /defaults

RUN --mount=type=secret,id=MONGODB_URL,mode=0444 \
    MODEL_NAME="${MODEL_NAME:="$(cat /defaults/MODEL_NAME)"}" && export MODEL_NAME \
    && MODEL_PARAMS="${MODEL_PARAMS:="$(cat /defaults/MODEL_PARAMS)"}" && export MODEL_PARAMS \
    && MODEL_PROMPT_TEMPLATE="${MODEL_PROMPT_TEMPLATE:="$(cat /defaults/MODEL_PROMPT_TEMPLATE)"}" && export MODEL_PROMPT_TEMPLATE \
    && APP_COLOR="${APP_COLOR:="$APP_COLOR"}" && export APP_COLOR \
    && APP_NAME="${APP_NAME:="$(cat /defaults/APP_NAME)"}" && export APP_NAME \
    && envsubst < "entrypoint.sh" > "entrypoint.sh" \
    && rm entrypoint.sh

RUN mkdir -p /data/db
RUN chown -R 1000:1000 /data

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | /bin/bash -

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app
RUN chown -R 1000:1000 /app

RUN useradd -m -u 1000 user

# Switch to the "user" user
USER user

ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

RUN npm config set prefix /home/user/.local
RUN npm install -g pm2

COPY --from=chatui-builder --chown=1000 /app/chat-ui/node_modules /app/node_modules
COPY --from=chatui-builder --chown=1000 /app/chat-ui/package.json /app/package.json
COPY --from=chatui-builder --chown=1000 /app/chat-ui/build /app/build

ENTRYPOINT ["/bin/bash"]
CMD ["entrypoint.sh"]


