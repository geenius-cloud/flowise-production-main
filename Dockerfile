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

# Create the backup script
RUN echo '#!/bin/bash\npython3 /usr/src/backup.py' > /usr/src/backup.sh
RUN chmod +x /usr/src/backup.sh

# Set up cron job to run at 11:30 AM EST (16:30 UTC)
RUN echo "30 16 * * * /usr/src/backup.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Ensure cron log file is created
RUN touch /var/log/cron.log

EXPOSE 3000

# Start cron, run the backup script immediately, and then start the main service
CMD crond && /usr/src/backup.sh && tail -f /var/log/cron.log & pnpm start
