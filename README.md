# Bashbot Setup/Deployment Examples

[BashBot](https://github.com/mathew-fleisch/bashbot) is a chat-ops tool written in golang for infrastructure/devops teams. [A json configuration file](bashbot/config.json), saved in this repository, is used to extend custom scripts and automation from your existing processes, to Slack. Commands can be restricted to private channels and/or use metadata from the user who triggers each command, as input, when Bashbot executes your scripts and automation. This repository shows some examples of how you can deploy Bashbot in your infrastructure and run locally for testing. Fork this repository and use the method that makes sense for your team's needs. Multiple instances of Bashbot can be run using the same slack token, but the triggers should be different to avoid multiple responses. Contributions to [BashBot](https://github.com/mathew-fleisch/bashbot) are welcome!

<img src="https://i.imgur.com/s0cf2Hl.gif" />

## Table of Contents

- ***First-Time Setup***
  - [Setup Step 0: Make the slack app and get a token](#setup-step-0-make-the-slack-app-and-get-a-token)
  - [Setup Step 1: Fork this repository](#setup-step-1-fork-this-repository)
  - [Setup Step 2: Create deploy key](#setup-step-2-create-deploy-key) (handy for private "forks")
  - [Setup Step 3: Upload public deploy key](#setup-step-3-upload-public-deploy-key)
  - [Setup Step 4: Save deploy key as github secret](#setup-step-4-save-deploy-key-as-github-secret) (optional: used in github-actions) 

- Running Bashbot Locally
   - [***Go-Binary***](#run-bashbot-locally-as-go-binary)
   - [***Docker***](#run-bashbot-locally-from-docker)

- Deploy Bashbot
   - [Kubernetes](#run-bashbot-in-kubernetes)

- [Makefile targets](#makefile-targets)


------------------------------------------------------------------------

### Setup Step 0 Make the slack app and get a token

Create classic slack app and export the environment variable `SLACK_TOKEN` "Bot User OAuth Access Token" in a .env file in the same directory as the configuration for that instance of bashbot. The .env file can be mounted as a configmap in kubernetes, saved as a github secret for use in github-actions, or used locally to source tokens that Bashbot can leverage in scripts, in each deployment type.

 - Log into slack, in a browser and 'launch' your workspace from
    - https://app.slack.com/apps-manage/
 - Create a new "classic app" by filling out form
    - [https://api.slack.com/apps?new_classic_app=1](https://api.slack.com/apps?new_classic_app=1)

<img src="https://i.imgur.com/xgUDAOj.png" />

 - Click on "Bots" from the `basic information` screen

<img src="https://i.imgur.com/UHSVuYg.png" />

 - Add Legacy Bot User

<img src="https://i.imgur.com/R7XYWvi.png" />

<img src="https://i.imgur.com/q18MFSz.png" />

- Install Bashbot in your workspace

<img src="https://i.imgur.com/zwiSQWq.png" />

<img src="https://i.imgur.com/ppvjveV.png" />

- From the `OAuth & Permissions` screen, note the `Bot User OAuth Token` (starts with 'xoxb-') as the environment variable `SLACK_TOKEN` used later on

<img src="https://i.imgur.com/EXvWLmT.png" />

------------------------------------------------------------------------

### Setup Step 1 Fork this repository

json configuration can be saved in a private repository and use steps 2-4 to use a deploy key for read or read/write access. However, they are not necessary for a public fork of this repository.

------------------------------------------------------------------------

### Setup Step 2 Create deploy key

Replace "your_email@example.com" with your email and run the following command to generate a new ssh key

```bash
ssh-keygen \
   -q -N "" \
   -t rsa -b 4096 \
   -C "your_email@example.com" \
   -f ${PWD}/bashbot/id_rsa
```

------------------------------------------------------------------------

### Setup Step 3 Upload public deploy key

Using the id_rsa.pub file that is generated from the previous command, paste the contents in the key section and give it a title like `BASHBOT_READONLY`:

```
https://github.com/[FORK-OWNER]/bashbot-example/settings/keys
```

Note: Check the 'allow write access' box if this key should be able to modify it's own configuration. This is usually not necessary, and easy to change, so I'd recommend read-only unless you have a specific use case for Bashbot to need write access to its own configuration.

<img src="https://i.imgur.com/gmb66jy.png" />

------------------------------------------------------------------------

### Setup Step 4 Save deploy key as github secret

If you want to use github actions to manage a kubernetes deployment, save the id_rsa private key as a github secret

```
https://github.com/[FORK-OWNER]/bashbot-example/settings/secrets/actions
```

Click "New Repository Secret" on top right
<img src="https://i.imgur.com/ZjaTDTN.png" />

Paste the id_rsa in the 'value' box and give it a name like `BASHBOT_RO`
<img src="https://i.imgur.com/0Iva5gt.png" />

Verify secret is saved
<img src="https://i.imgur.com/QPHX7KS.png" />

------------------------------------------------------------------------



## Run Bashbot Locally As Go-Binary

The easiest way to run Bashbot as a go-binary is by using the makefile targets:

```bash
export BASH_CONFIG_FILEPATH=${PWD}/bashbot/config.json
export SLACK_TOKEN=xoxb-xxxxx-xxxxxxx
make install-latest
make run-binary
# ctrl+c to quit
```

Or "the hard way"

```bash
export BASH_CONFIG_FILEPATH=${PWD}/bashbot/config.json
export SLACK_TOKEN=xoxb-xxxxx-xxxxxxx

# ----------- Install binary -------------- #

# os: linux, darwin
export os=$(uname | tr '[:upper:]' '[:lower:]')

# arch: amd64, arm64
export arch=amd64
test "$(uname -m)" == "aarch64" && export arch=arm64

# Latest bashbot version/tag
export latest=$(curl -s https://api.github.com/repos/mathew-fleisch/bashbot/releases/latest | grep tag_name | cut -d '"' -f 4)

# Remove any existing bashbot binaries
rm -rf /usr/local/bin/bashbot || true

# Get correct binary for host machine and place in user's path
wget -qO /usr/local/bin/bashbot https://github.com/mathew-fleisch/bashbot/releases/download/${latest}/bashbot-${os}-${arch}

# Make bashbot binary executable
chmod +x /usr/local/bin/bashbot

# To verify installation run version or help commands
bashbot --version
# bashbot-darwin-amd64    v1.6.3

bashbot --help
#  ____            _     ____        _   
# |  _ \          | |   |  _ \      | |  
# | |_) | __ _ ___| |__ | |_) | ___ | |_ 
# |  _ < / _' / __| '_ \|  _ < / _ \| __|
# | |_) | (_| \__ \ | | | |_) | (_) | |_ 
# |____/ \__,_|___/_| |_|____/ \___/ \__|
# Bashbot is a slack bot, written in golang, that can be configured
# to run bash commands or scripts based on a configuration file.

# Usage: ./bashbot [flags]

#   -config-file string
#         [REQUIRED] Filepath to config.json file (or environment variable BASHBOT_CONFIG_FILEPATH set)
#   -help
#         Help/usage information
#   -install-vendor-dependencies
#         Cycle through dependencies array in config file to install extra dependencies
#   -log-format string
#         Display logs as json or text (default "text")
#   -log-level string
#         Log elevel to display (info,debug,warn,error) (default "info")
#   -send-message-channel string
#         Send stand-alone slack message to this channel (requires -send-message-text)
#   -send-message-ephemeral
#         Send stand-alone ephemeral slack message to a specific user (requires -send-message-channel -send-message-text and -send-message-user)
#   -send-message-text string
#         Send stand-alone slack message (requires -send-message-channel)
#   -send-message-user string
#         Send stand-alone ephemeral slack message to this slack user (requires -send-message-channel -send-message-text and -send-message-ephemeral)
#   -slack-token string
#         [REQUIRED] Slack token used to authenticate with api (or environment variable SLACK_TOKEN set)
#   -version
#         Get current version
```


Once the binary is installed, and environment variables have been set, install vendor dependencies and then run the bashbot binary with no parameters.

```bash
# ----------- Run binary -------------- #
# From bashbot source root, create a "vendor" directory for vendor dependencies
mkdir -p vendor && cd vendor

# Use bashbot binary to install vendor dependencies from the vendor directory
bashbot --install-vendor-dependencies

# From bashbot source root run the bashbot binary
cd ..
bashbot

```


------------------------------------------------------------------------

## Run Bashbot Locally From Docker

```bash
export BASH_CONFIG_FILEPATH=${PWD}/bashbot/config.json
export SLACK_TOKEN=xoxb-xxxxx-xxxxxxx

make docker-run
```

Or "the hard way"

```bash
export BASH_CONFIG_FILEPATH=${PWD}/bashbot/config.json
export SLACK_TOKEN=xoxb-xxxxx-xxxxxxx

docker run --rm \
   --name bashbot \
   -v ${BASHBOT_CONFIG_FILEPATH}:/bashbot/config.json \
   -e BASHBOT_CONFIG_FILEPATH="/bashbot/config.json" \
   -e SLACK_TOKEN=${SLACK_TOKEN} \
   -e LOG_LEVEL="info" \
   -e LOG_FORMAT="text" \
   -it mathewfleisch/bashbot:latest



# Or mount secrets and docker socket (mac)
docker run --rm \
   --name bashbot \
   -v /var/run/docker.sock:/var/rund/docker.sock \
   -v ${BASHBOT_CONFIG_FILEPATH}:/bashbot/config.json \
   -e BASHBOT_CONFIG_FILEPATH="/bashbot/config.json" \
   -e SLACK_TOKEN=${SLACK_TOKEN} \
   -v ${PWD}/bashbot/.env:/bashbot/.env \
   -v ${PWD}/bashbot/id_rsa:/root/.ssh/id_rsa \
   -v ${PWD}/bashbot/id_rsa.pub:/root/.ssh/id_rsa.pub \
   -e LOG_LEVEL="info" \
   -e LOG_FORMAT="text" \
   -it mathewfleisch/bashbot:latest





# Or mount secrets and docker socket (linux)
docker run --rm \
   --name bashbot \
   -v /var/run/docker.sock:/var/run/docker.sock \
   --group-add $(stat -c '%g' /var/run/docker.sock) \
   -v ${BASHBOT_CONFIG_FILEPATH}:/bashbot/config.json \
   -e SLACK_TOKEN=${SLACK_TOKEN} \
   -e BASHBOT_CONFIG_FILEPATH="/bashbot/config.json" \
   -v ${PWD}/bashbot/.env:/bashbot/.env \
   -v ${PWD}/bashbot/id_rsa:/root/.ssh/id_rsa \
   -v ${PWD}/bashbot/id_rsa.pub:/root/.ssh/id_rsa.pub \
   -e LOG_LEVEL="info" \
   -e LOG_FORMAT="text" \
   -it mathewfleisch/bashbot:latest



# Exec into bashbot container
docker exec -it $(docker ps -aqf "name=bashbot") bash

# Remove existing bashbot container
docker rm $(docker ps -aqf "name=bashbot")
```



------------------------------------------------------------------------

## Run Bashbot in Kubernetes


***Requirements***

- kubernetes
- configmaps
  - id_rsa, id_rsa.pub (deploy key to bashbot config json)
  - config json
  - .env file (with `SLACK_TOKEN` and `BASHBOT_CONFIG_FILEPATH` set)

In this deployment method, a "seed" configuration is set as the default configuration json for bashbot. The seed configuration will use a pem file, to clone a private repository, with the actual configuration. The seed configuration is executed when a bashbot pod first spins up, and replaces itself with the latest from a configuration repository (that you set up and can/should be private). This method ensures bashbot is using the latest configuration every time a new pod spins up (deleting a pod will update the running configuration), and is not baked into the container running the bashbot go-binary. A `.env` file is also injected as a configmap containing the `SLACK_TOKEN` and `BASHBOT_CONFIG_FILEPATH` and any other passwords or tokens exported as environment variables. After the seed configuration json is replaced with a configuration json from the private repository `bashbot-example` the bashbot binary is used to install any tools or packages defined in the `dependencies` section of the json using the `--install-vendor-dependencies` flag. It is also possible to mount the main configuration json as a configmap as well, but the seed method allows the configuration json to be modified in place. If the configuration json is mounted directly (via configmap), commands like [add-example](examples/add-example) and [remove-example](examples/remove-example) would not be able to modify the configmap, holding the configuration json, and would error. Note: If the configuration json is mounted directly, remove `cp seed.json config.json &&` from the args value in the deployment yaml.

Start by pushing the [sample-config.json](sample-config.json) file to a private repository and set up a [deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys) following the setup steps:
  - id_rsa
  - id_rsa.pub
  - seed/config.json
  - config.json
  - .env

Example .env

```bash
export SLACK_TOKEN=xoxb-xxxxxxxxx-xxxxxxx
export BASHBOT_CONFIG_FILEPATH=/bashbot/config.json
export AIRQUALITY_API_KEY=1234567890
```

Example seed/config.json uses the mounted configmaps to authenticate with github via ssh, and clone the repository where the bashbot configs are saved. Using this method allows the pod running Bashbot to easily update Bashbot to use the latest configuration from github. Deleting the pod running Bashbot, forces this seed process to execute, when the pod is replaced by the Kubernetes deployment.

Note: filename must be config.json to match deployment yaml

```json
{
  "admins": [
    {
      "trigger": "bashbot",
      "appName": "BashBotSeed",
      "userIds": [],
      "privateChannelId": "",
      "logChannelId": ""
    }],
  "messages": [],
  "tools": [],
  "dependencies": [
    {
      "name": "Private configuration repository",
      "install": [
        "if [[ -f /root/.ssh/keys/id_rsa ]]; then",
          "cp /root/.ssh/keys/id_rsa /root/.ssh/id_rsa",
          "&& cp /root/.ssh/keys/id_rsa.pub /root/.ssh/id_rsa.pub",
          "&& chmod 600 /root/.ssh/id_rsa",
          "&& ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts",
          "&& git config user.name bashbot-github-user",
          "&& git config user.email bashbot-github-user@company.com",
          "&& rm -rf bashbot-example || true",
          "&& git clone git@github.com:mathew-fleisch/bashbot-example.git",
          "&& source /bashbot/.env",
          "&& cp bashbot-example/bashbot/config.json $BASHBOT_CONFIG_FILEPATH",
          "&& cd /bashbot",
          "&& bashbot --install-vendor-dependencies",
          "&& echo \"Bashbot's configuration is up to date\";",
        "else",
          "echo \"id_rsa missing, skipping private repo: bashbot-example\";",
        "fi"
      ]
    }
  ]
}
```

Example deployment yaml mounts the configmaps and copies the seed configuration in place before executing the entrypoint script. Note: Bashbot is currently not set up for federation, so there should only ever be one replica of each deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: bashbot
  name: bashbot
  namespace: bashbot
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 0
  selector:
    matchLabels:
      app: bashbot
  strategy:
    type: Recreate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: bashbot
    spec:
      containers:
        - env:
            - name: BASHBOT_ENV_VARS_FILEPATH
              value: /bashbot/.env
          image: mathewfleisch/bashbot:v1.6.3
          imagePullPolicy: IfNotPresent
          name: bashbot
          command: ["/bin/sh"]
          args: ["-c", "cp seed.json config.json && ./entrypoint.sh"]
          # To override entrypoint and poke around:
          # args: ["-c", "while true; do echo hello; sleep 10;done"]
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          workingDir: /bashbot
          volumeMounts:
            - name: config-json
              mountPath: /bashbot/seed.json
              subPath: config.json
            - name: id-rsa
              mountPath: /root/.ssh/keys/id_rsa
              subPath: id_rsa
            - name: id-rsa-pub
              mountPath: /root/.ssh/keys/id_rsa.pub
              subPath: id_rsa.pub
            - name: env-vars
              mountPath: /bashbot/.env
              subPath: .env
      volumes:
        - name: id-rsa
          configMap:
            name: bashbot-id-rsa
        - name: id-rsa-pub
          configMap:
            name: bashbot-id-rsa-pub
        - name: config-json
          configMap:
            name: bashbot-config
        - name: env-vars
          configMap:
            name: bashbot-env
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 0
```


With the configuration json, .env file and deployment public/private keys saved, they can be mounted as configmaps and the deployment can be applied to the cluster.

```bash
# Create bashbot namespace
kubectl create namespace bashbot

# Define configmaps
bot_name=bashbot
make config-maps

# Finally apply the deployment
kubectl -n bashbot apply -f bashbot/deployment-bashbot.yaml

# List bashbot instances
kubectl -n bashbot get pods
# NAME                            READY   STATUS    RESTARTS   AGE
# bashbot-7cd5577c5c-5dwsl        1/1     Running   0          5d23h
```




------------------------------------------------------------------------

## Makefile Targets

A Makefile is included in this repository to make common actions easier to execute.

 - `make install-latest`
   - This target will download the latest go-binary to `/usr/local/bin/bashbot`
 - `make run-binary`
   - This target will attempt to install vendor dependencies and run bashbot
 - `make int-run-binary`
   - This target is not meant to be run externally, and is used as a workaround to clean-up vendor dependencies after exiting `make run-binary`
 - `make docker-build-alpine`
   - This target will build an alpine container, install linters and bashbot through asdf
 - `make docker-build-ubuntu`
   - This target will build an ubuntu container, install linters and bashbot through asdf
 - `make docker-run`
   - This target will run bashbot in the dockerhub docker container
 - `make docker-run-local`
   - This target will run bashbot in a docker container built by `make docker-build-alpine` or `make docker-build-ubuntu`
 - `make docker-exec`
   - This target will exec into a running docker container named 'bashbot'
 - `bot_name=bashbot make config-maps`
   - This target will overwrite any existing configmaps for the bot/directory `bashbot`
 - `bot_name=bashbot make get`
   - This target will print pod information on the bot/directory `bashbot`
 - `bot_name=bashbot make delete`
   - This target will delete the pod with the bot/directory `bashbot`
 - `bot_name=bashbot make describe`
   - This target will describe the pod with the bot/directory `bashbot`
 - `bot_name=bashbot make exec`
   - This target will exec into the pod with the bot/directory `bashbot`
 - `bot_name=bashbot make logs`
   - This target will tail the logs of the pod with the bot/directory `bashbot`


------------------------------------------------------------------------


## To Do

Define examples for storing/encrypting secrets like .env and any deployment keys.