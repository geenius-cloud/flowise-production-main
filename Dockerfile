# Build local monorepo image
# docker build --no-cache -t  flowise .

# Run image
# docker run -d -p 3000:3000 flowise

FROM node:20-alpine

RUN apk add --update libc6-compat python3 py3-pip make g++ build-base cairo-dev pango-dev chromium bash curl
RUN npm install -g pnpm
RUN python3 -m venv /venv
RUN /venv/bin/pip install boto3 schedule

ENV PATH="/venv/bin:$PATH"

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /usr/src

COPY . .

RUN pnpm install
RUN pnpm build

EXPOSE 3000

CMD python3 backup.py & pnpm start
