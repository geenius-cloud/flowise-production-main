# Build local monorepo image
# docker build --no-cache -t  flowise .

# Run image
# docker run -d -p 3000:3000 flowise

FROM node:20-alpine

# Install necessary packages
RUN apk add --update libc6-compat python3 py3-pip make g++ build-base cairo-dev pango-dev chromium bash curl

# Install PNPM globally
RUN npm install -g pnpm

# Create a virtual environment for Python and install boto3
RUN python3 -m venv /venv
RUN /venv/bin/pip install boto3

# Set the virtual environment as the default for all subsequent commands
ENV PATH="/venv/bin:$PATH"

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /usr/src

# Copy app source
COPY . .

RUN pnpm install
RUN pnpm build

# Install cron
RUN apk add --no-cache tzdata
RUN apk add --no-cache busybox-suid
RUN apk add --no-cache cronie

# Copy the cronjob file to the container
COPY cronjob /etc/crontabs/root

# Ensure cron log file is created
RUN touch /var/log/cron.log

EXPOSE 3000

# Start cron and the main service
CMD crond -f & pnpm start
