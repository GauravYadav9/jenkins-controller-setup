# Start from the official, unmodified Jenkins image
FROM jenkins/jenkins:lts-jdk21

# Switch to root to perform all setup tasks
USER root

# Install prerequisites for Docker's repository
RUN apt-get update && apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key and set up the repository
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install the Docker CLI package
RUN apt-get update && apt-get install -y docker-ce-cli

# --- JCasC SETUP (STILL AS ROOT) ---

# Copy curated plugins list and install via jenkins-plugin-cli
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Seed casc.yaml so it is copied to JENKINS_HOME on first run
COPY casc.yaml /usr/share/jenkins/ref/casc.yaml

# Default CASC path for standalone 'docker run'; docker-compose.yml overrides to /casc
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

# Switch back to jenkins user for runtime security
USER jenkins