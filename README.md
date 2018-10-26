# ibm-jenkins-slave-nvm

## Introduction

A jenkins slave image supports:

- ssh-slave
- [Node Version Manager](https://github.com/creationix/nvm)
- node.js v8.11.4 installed by nvm
- [JFrog CLI](https://jfrog.com/getcli/)
- Firefox v61.0.2 for headless Selenium test
- gnome-keyring and keytar
- [w3c Link Checker](https://github.com/w3c/link-checker)
- Other Ubuntu packages:
  * curl
  * wget
  * pax
  * bzip2
  * rsync
  * vim
  * sshpass
  * jq

Currently published to [Docker hub: jackjiaibm/ibm-jenkins-slave-nvm](https://hub.docker.com/r/jackjiaibm/ibm-jenkins-slave-nvm/).

## About Base Image

`openjdk:8-jdk` which is Debian 9 (Stretch).

This docker image is a modified version from official `jenkins/ssh-slave`, and can be used as `Connect method` - `Connect with SSH` with user `jenkins`. The modification is installing nvm before declare "VOLUME /home/jenkins", so changes done by nvm install can be saved.

## About Node Version Manager

With nvm, the jenkins user doesn't require sudo to run `npm install`. This is explanation from npmjs.org: https://docs.npmjs.com/getting-started/fixing-npm-permissions#option-one-reinstall-with-a-node-version-manager.
