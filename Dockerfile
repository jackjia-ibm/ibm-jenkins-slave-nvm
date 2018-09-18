FROM openjdk:8-jdk

#####################################################
# arguments
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}
ARG NODE_VERSION=8.11.4
ARG FIREFOX_VERSION=61.0.2
ARG FIREFOX_LANGUAGE=en-US

#####################################################
# environments
ENV DEBIAN_FRONTEND noninteractive
ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}
ENV NODE_VERSION ${NODE_VERSION}
ENV NVM_VERSION 0.33.11

#####################################################
# create jenkins user
RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

#####################################################
# install required packages
# - build-essential: provide make and gcc which will be used in "npm install"
# - sshpass: allow ssh to other servers
# - bzip2: used by installing firefox
# - gnome-keyring: required by keytar
# - libsecret-1-dev: required by npm install rebuild keytar
# - dbus-x11: includes dbus-launch
# - libdbus-glib-1-2: used by firefox
RUN apt-get update && apt-get install --no-install-recommends -y \
    openssh-server \
    vim curl wget build-essential sshpass bzip2 locales \
    gnome-keyring libsecret-1-dev dbus dbus-user-session dbus-x11 \
    libdbus-glib-1-2 \
   && rm -rf /var/lib/apt/lists/*

#####################################################
# configure locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && /usr/sbin/locale-gen

#####################################################
# install firefox
ADD https://archive.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/KEY KEY
ADD https://archive.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/SHA512SUMS SHA512SUMS
ADD https://archive.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/SHA512SUMS.asc SHA512SUMS.asc
RUN gpg --import KEY \
    && gpg --verify SHA512SUMS.asc \
    && rm KEY \
    && rm SHA512SUMS.asc
# need RUN rather than ADD or COPY because both ADD and COPY are silently unzipping the archive
RUN wget --no-verbose --show-progress --progress=dot:giga --directory-prefix linux-x86_64/${FIREFOX_LANGUAGE} https://archive.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/${FIREFOX_LANGUAGE}/firefox-${FIREFOX_VERSION}.tar.bz2 \
    && grep linux-x86_64/${FIREFOX_LANGUAGE}/firefox-${FIREFOX_VERSION}.tar.bz2 SHA512SUMS | sha512sum -c - \
    && rm SHA512SUMS \
    && tar --extract --bzip2 --file linux-x86_64/${FIREFOX_LANGUAGE}/firefox-${FIREFOX_VERSION}.tar.bz2 --directory /usr/lib/ \
    && rm -fr linux-x86_64 \
    && ln -fs /usr/lib/firefox/firefox /usr/bin/firefox

#####################################################
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

#####################################################
# Copy the PAM configuration options to allow auto unlocking of the gnome keyring
COPY pam.config /tmp/pam.config
# Enable unlocking for ssh/login
RUN cat /tmp/pam.config >> /etc/pam.d/sshd \
    && cat /tmp/pam.config >> /etc/pam.d/login \
    && rm /tmp/pam.config

COPY .bashrc_all /tmp/.bashrc_all
COPY .bashrc_ni /home/jenkins/.bashrc_ni
# prepend to ~/.bashrc
RUN sed -i -e "/# If not running interactively, don't do anything/r /tmp/.bashrc_all" -e //N /home/jenkins/.bashrc

#####################################################
# install nvm on jenkins user
# switch to jenkins user
USER jenkins
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash
ENV NVM_DIR /home/jenkins/.nvm
# install node version and set it as the default one
RUN /bin/bash -c "source ${NVM_DIR}/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default && npm install -g jfrog-cli-go"
# define volume
VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"
# switch back to root user
USER root

#####################################################
# expose and entrypoint
EXPOSE 22
ENTRYPOINT ["/usr/local/bin/setup-sshd"]
