# Inherit from Heroku's stack
FROM heroku/heroku:18

# Internally, we arbitrarily use port 3000
ENV PORT 3000
# Make sure apt-get does not ask us questions
ENV DEBIAN_FRONTEND noninteractive
# Which version of node?
ENV NODE_VERSION 12.9.1
ENV YARN_VERSION 1.22.4
# Locate our binaries
ENV PATH /app/heroku/node/bin/:/app/user/node_modules/.bin:$PATH

# Following line fixes
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Create some needed directories
RUN mkdir -p /app/heroku/node /app/.profile.d
WORKDIR /app/user

# Install Node
RUN curl -s --retry 3 -L http://s3pository.heroku.com/node/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz | tar xz -C /app/heroku/node/
RUN mv /app/heroku/node/node-v$NODE_VERSION-linux-x64 /app/heroku/node/node-$NODE_VERSION
ENV PATH /app/heroku/node/node-$NODE_VERSION/bin:$PATH

# Export the node path in .profile.d
RUN echo "export PATH=\"/app/heroku/node-$NODE_VERSION/bin:/app/user/node_modules/.bin:\$PATH\"" > /app/.profile.d/nodejs.sh

# Install protractor and webdriver globally
RUN npm install -g protractor && webdriver-manager update --standalone false --gecko false

# Install Yarn
RUN curl -s --retry 3 -L https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz | tar xz -C /app/heroku/node/
RUN mv /app/heroku/node/yarn-v$YARN_VERSION /app/heroku/node/yarn-$YARN_VERSION
ENV PATH /app/heroku/node/yarn-$YARN_VERSION/bin:$PATH

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && DEBIAN_FRONTEND=noninteractive apt-get -qqy install xvfb google-chrome-stable \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/*

# run npm or yarn install
# add yarn.lock to .slugignore in your project
ONBUILD ADD package*.json yarn.* /app/user/
ONBUILD RUN [ -f yarn.lock ] && yarn install --no-progress || npm install
ONBUILD RUN if command -v ngcc; then ngcc; else echo 'No ngcc detected'; fi

# Add files
ONBUILD ADD . /app/user/
