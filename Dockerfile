FROM jenkins/jnlp-slave

ARG NODE_VERSION=8.11.4

ENV NODE_VERSION ${NODE_VERSION}
ENV NVM_VERSION 0.33.11

USER root
# install required packages
# - build-essential: provide make and gcc which will be used in "npm install"
# - sshpass: allow ssh to other servers
# - gnome-keyring: required by keytar
# - libsecret-1-dev: required by npm install rebuild keytar
RUN apt-get update && apt-get install -y \
    curl build-essential sshpass \
    gnome-keyring libsecret-1-dev \
   && rm -rf /var/lib/apt/lists/*

# Copy the PAM configuration options to allow auto unlocking of the gnome keyring
COPY pam.config /tmp/pam.config
# Enable unlocking for ssh
RUN cat /tmp/pam.config >> /etc/pam.d/sshd
# Enable unlocking for regular login
RUN cat /tmp/pam.config >> /etc/pam.d/login
RUN rm /tmp/pam.config

# Add to the .bashrc configuration with additional options for auto launching a dbus-session
COPY .bashrc /tmp/.bashrc
RUN cat /tmp/.bashrc >> /home/jenkins/.bashrc
RUN rm /tmp/.bashrc

# switch to jenkins user
USER jenkins

# install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash
ENV NVM_DIR /home/jenkins/.nvm
# install node version and set it as the default one
RUN /bin/bash -c "source ${NVM_DIR}/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
