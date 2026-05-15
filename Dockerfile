# Base image: Ruby with necessary dependencies for Jekyll
FROM ruby:3.1

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally (as root, before switching to non-root user)
RUN npm install -g @anthropic-ai/claude-code


# Create a non-root user with UID 1000
RUN groupadd -g 1000 vscode && \
    useradd -m -u 1000 -g vscode vscode

# Set the working directory
WORKDIR /usr/src/app

# Set permissions for the working directory
RUN chown -R vscode:vscode /usr/src/app

# Switch to the non-root user
USER vscode

# Copy dependency manifests so bundler installs the exact locked gem set.
COPY --chown=vscode:vscode Gemfile Gemfile.lock ./



# Install bundler and dependencies
RUN gem install connection_pool:2.5.0
RUN gem install bundler:2.5.11
RUN bundle install

# Command to serve the Jekyll site
CMD ["bundle", "exec", "jekyll", "serve", "-H", "0.0.0.0", "--no-watch", "--config", "_config.yml,_config_docker.yml"]
