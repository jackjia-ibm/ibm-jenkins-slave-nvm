# ibm-jenkins-slave-nvm

Jenkins slave has [Node Version Manager](https://github.com/creationix/nvm) installed, and Node.JS LTS v8.11.3 is installed by nvm.

With nvm, the jenkins user doesn't require sudo to run `npm install`. This is explanation from npmjs.org: https://docs.npmjs.com/getting-started/fixing-npm-permissions#option-one-reinstall-with-a-node-version-manager.

Currently published to [jackjiaibm/ibm-jenkins-slave-nvm](https://hub.docker.com/r/jackjiaibm/ibm-jenkins-slave-nvm/).

This docker image is based on official `jenkins/jnlp-slave`, and can be used as `Connect method` - `Attached Docker container` with user `jenkins`.
