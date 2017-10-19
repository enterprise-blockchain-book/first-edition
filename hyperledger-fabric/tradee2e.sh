#!/bin/bash

#
# Trade Finance Network Script. The script files is build upon first network sample application.
# 
# The script provides an end to-end execution of Trade Finance Network as described in the book -
# Enterprise Blockchain - A Definitive Handbook
#


export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export COMPOSE_PROJECT_NAME="tradee2e"

# Print the usage message
function printHelp () {
  echo "Usage: Trade Finance E2E CLI Application"
  echo "  treadee2e.sh -m up|down|restart|generate"
  echo "  treadee2e.sh -h|--help (print this message)"
  echo "    -m <mode> - one of 'up', 'down', 'restart' or 'generate'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo " Default usage:"
  echo "	treadee2e.sh -m generate"
  echo "	treadee2e.sh -m up"
  echo "	treadee2e.sh -m down"
}

function clearContainers () {
  CONTAINER_IDS=$(docker ps -aq)
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Generate certificate based on Trade Finance Network Topology using cryptogen tool.
# Generate Channel artifacts for Trade Finance Network Topology
function networkUp () {
  # generate artifacts if they don't exist
  if [ ! -d "crypto-config" ]; then
    generateCerts
    generateChannelArtifacts
  fi
  CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=$CLI_TIMEOUT DELAY=$CLI_DELAY docker-compose -f $COMPOSE_FILE up -d 2>&1

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    docker logs -f cli
    exit 1
  fi
  docker logs -f cli
}

# Tear down running network
function networkDown () {
  docker-compose -f $COMPOSE_FILE down
  if [ "$MODE" != "restart" ]; then
    clearContainers
    removeUnwantedImages
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config
   fi
}



# Generates Certificates for Trade Finance Network using cryptogen tool
function generateCerts (){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "Generate certificates using cryptogen tool .."
  echo

  cryptogen generate --config=./crypto-config.yaml
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates."
    exit 1
  fi
  echo
}


# Generate channel artifacts for Trade Finance Network. This includes the starting block - orderer genesis block, 
# channel configuration for our 3 organisations in Trade Finance Network and  optional anchor peers for each of the Organisation
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo ".. Generating Orderer Genesis block ..."
  configtxgen -profile TradeFinanceOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block."
    exit 1
  fi
  echo
  echo "..Generating channel configuration transaction 'channel.tx'.."
  configtxgen -profile TradeFinanceOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration artifact."
    exit 1
  fi
  echo
}

# Obtain native binaries based on platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
CLI_TIMEOUT=10000
CLI_DELAY=4
CHANNEL_NAME="tradechannel"
COMPOSE_FILE=docker-trade-finance.yaml


# Parse commandline args
while getopts "h?m:c:t:d:f:s:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    m)  MODE=$OPTARG
    ;;
 
  esac
done

# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
  elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
  elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting"
  elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block for Trade Finance Network"
else
  printHelp
  exit 1
fi


# Command line options
if [ "${MODE}" == "up" ]; then
  networkUp
  elif [ "${MODE}" == "down" ]; then 
  networkDown
  elif [ "${MODE}" == "generate" ]; then 
  generateCerts
  generateChannelArtifacts
  elif [ "${MODE}" == "restart" ]; then 
  networkDown
  networkUp
else
  printHelp
  exit 1
fi
