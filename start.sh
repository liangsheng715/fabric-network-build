#!/bin/bash

# 遇到报错退出程序
set -e

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="mychaincode"

  echo "##########################################################"
  echo "##### Clean up the environment                   #########"
  echo "##########################################################"
mkdir -p crypto-config
mkdir -p channel-artifacts
rm -rf channel-artifacts/*
rm -rf crypto-config/*

  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"
cryptogen generate --config=./crypto-config.yaml

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
configtxgen -profile SampleMultiNodeEtcdRaft -outputBlock ./channel-artifacts/genesis.block

  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

  echo "#################################################################"
  echo "#######    Generating anchor peer update for organization1MSP   ##########"
  echo "#################################################################"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/organization1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg organization1MSP

  echo "#################################################################"
  echo "#######    Generating anchor peer update for organization2MSP   ##########"
  echo "#################################################################"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/organization2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg organization2MSP

  echo "#################################################################"
  echo "#######    docker-compose up                           ##########"
  echo "#################################################################"
docker-compose -f docker-compose-cli.yaml -f docker-compose-etcdraft2.yaml up -d

sleep 15s

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo

ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
NODE1_ORG2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/peers/node1.organization2.example.com/tls/ca.crt

echo "Creating channel..."
docker exec cli peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls true --cafile $ORDERER_CA


echo "Having all peers join the channel..."
docker exec cli peer channel join -b $CHANNEL_NAME.block
docker exec -e CORE_PEER_ADDRESS=node2.organization1.example.com:7051 cli peer channel join -b $CHANNEL_NAME.block

docker exec -e CORE_PEER_TLS_ROOTCERT_FILE=$NODE1_ORG2_CA -e CORE_PEER_ADDRESS=node1.organization2.example.com:7051 -e CORE_PEER_LOCALMSPID=organization2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/users/Admin@organization2.example.com/msp cli peer channel join -b $CHANNEL_NAME.block
docker exec -e CORE_PEER_TLS_ROOTCERT_FILE=$NODE1_ORG2_CA -e CORE_PEER_ADDRESS=node2.organization2.example.com:7051 -e CORE_PEER_LOCALMSPID=organization2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/users/Admin@organization2.example.com/msp cli peer channel join -b $CHANNEL_NAME.block

echo "Updating anchor peers for org1..."
docker exec -e CORE_PEER_ADDRESS=node2.organization1.example.com:7051 cli peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/organization1MSPanchors.tx --tls true --cafile $ORDERER_CA

echo "Updating anchor peers for org2..."
docker exec -e CORE_PEER_TLS_ROOTCERT_FILE=$NODE1_ORG2_CA -e CORE_PEER_ADDRESS=node2.organization2.example.com:7051 -e CORE_PEER_LOCALMSPID=organization2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/users/Admin@organization2.example.com/msp cli peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/organization2MSPanchors.tx --tls true --cafile $ORDERER_CA

echo "Installing chaincode on node1.org1..."
docker exec cli peer chaincode install -n $CHAINCODE_NAME -v 1.0 -l golang -p "github.com/chaincode/example"

echo "Install chaincode on node1.org2..."
docker exec -e CORE_PEER_TLS_ROOTCERT_FILE=$NODE1_ORG2_CA -e CORE_PEER_ADDRESS=node1.organization2.example.com:7051 -e CORE_PEER_LOCALMSPID=organization2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/users/Admin@organization2.example.com/msp cli peer chaincode install -n $CHAINCODE_NAME -v 1.0 -l golang -p "github.com/chaincode/example"

echo "Instantiating chaincode on node1.org1..."
docker exec cli peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n $CHAINCODE_NAME -l golang -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('organization1MSP.peer','organization2MSP.peer')" --tls true --cafile $ORDERER_CA

echo "Instantiating chaincode on node1.org2..."
docker exec -e CORE_PEER_TLS_ROOTCERT_FILE=$NODE1_ORG2_CA -e CORE_PEER_ADDRESS=node1.organization2.example.com:7051 -e CORE_PEER_LOCALMSPID=organization2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/organization2.example.com/users/Admin@organization2.example.com/msp cli peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n $CHAINCODE_NAME -l golang -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('organization1MSP.peer','organization2MSP.peer')" --tls true --cafile $ORDERER_CA






