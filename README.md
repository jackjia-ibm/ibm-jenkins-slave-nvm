# ibm-jenkins-slave-nvm

Jenkins slave has [Node Version Manager](https://github.com/creationix/nvm) installed, and Node.JS LTS v8.11.4 is installed by nvm.

With nvm, the jenkins user doesn't require sudo to run `npm install`. This is explanation from npmjs.org: https://docs.npmjs.com/getting-started/fixing-npm-permissions#option-one-reinstall-with-a-node-version-manager.

Currently published to [jackjiaibm/ibm-jenkins-slave-nvm](https://hub.docker.com/r/jackjiaibm/ibm-jenkins-slave-nvm/).

This docker image is a modified version from official `jenkins/ssh-slave`, and can be used as `Connect method` - `Connect with SSH` with user `jenkins`. The modification is installing nvm before declare "VOLUME /home/jenkins", so changes done by nvm install can be saved.
