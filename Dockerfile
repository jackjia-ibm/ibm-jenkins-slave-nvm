FROM openjdk:8-jdk

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}
ARG NODE_VERSION=8.11.4

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}
ENV NODE_VERSION ${NODE_VERSION}
ENV NVM_VERSION 0.33.11

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

# install required packages
# - build-essential: provide make and gcc which will be used in "npm install"
# - sshpass: allow ssh to other servers
# - gnome-keyring: required by keytar
# - libsecret-1-dev: required by npm install rebuild keytar
# - dbus-x11: includes dbus-launch
RUN apt-get update && apt-get install --no-install-recommends -y \
    openssh-server \
    vim curl build-essential sshpass \
    gnome-keyring libsecret-1-dev dbus dbus-user-session dbus-x11 \
   && rm -rf /var/lib/apt/lists/*

# setup SSH server
RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd
COPY setup-sshd /usr/local/bin/setup-sshd
RUN chmod +x /usr/local/bin/setup-sshd

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
RUN cat /home/jenkins/.bashrc
ENV NVM_DIR /home/jenkins/.nvm
# install node version and set it as the default one
RUN /bin/bash -c "source ${NVM_DIR}/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

# switch to root user
USER root

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/setup-sshd"]
