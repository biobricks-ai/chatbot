---
title: BiobricksChat
emoji: 🚀
colorFrom: indigo
colorTo: blue
sdk: docker
pinned: false
app_port: 3000
suggested_hardware: a10g-small
license: unknown
---

Check out the configuration reference at https://huggingface.co/docs/hub/spaces-config-reference

# DEVELOPMENT
Open in a devcontainer

1. start mongo `docker compose run -p 27017:27017 mongo`
2. go to `cd chat-ui`
3. install dependencies `npm install`
4. start service `npm run dev -- --open`