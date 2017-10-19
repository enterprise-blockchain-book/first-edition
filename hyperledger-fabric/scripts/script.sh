#!/bin/bash

echo "Trade Finance End to End Application Script."
echo
CHANNEL_NAME="tradechannel"
DELAY="$2"
: ${CHANNEL_NAME:="tradechannel"}
: ${TIMEOUT:="60"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fte.com/orderers/orderer.fte.com/msp/tlscacerts/tlsca.fte.com-cert.pem
TRADE_ID="FTE_2"

echo "Channel name : "$CHANNEL_NAME

# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "Trace "$2" "
    echo "ERROR - FAILED to execute Trade Finance End to End Application."
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1FTE"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/peers/peer0.app.fte.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/users/Admin@app.fte.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.app.fte.com:7051
		else
			CORE_PEER_ADDRESS=peer1.app.fte.com:7051
			CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/users/Admin@app.fte.com/msp
		fi
	elif [ $1 -eq 2 -o $1 -eq 3 ] ; then
		CORE_PEER_LOCALMSPID="Org2BNK"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/peers/peer0.bnk.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/users/Admin@bnk.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.bnk.com:7051
		else
			CORE_PEER_ADDRESS=peer1.bnk.com:7051
		fi
	elif [ $1 -eq 4 -o $1 -eq 5 ] ; then
		CORE_PEER_LOCALMSPID="Org3SHP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/shp.com/peers/peer0.shp.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/shp.com/users/Admin@shp.com/msp
		if [ $1 -eq 4 ]; then
			CORE_PEER_ADDRESS=peer0.shp.com:7051
		else
			CORE_PEER_ADDRESS=peer1.shp.com:7051
		fi
	 
	 #Importer Bank
	 elif [ $1 -eq 6 ] ; then
		CORE_PEER_LOCALMSPID="Org2BNK"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/peers/peer0.bnk.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/users/User1@bnk.com/msp
		CORE_PEER_ADDRESS=peer0.bnk.com:7051
		PEER=PEER2

	 #Exporter Bank
	 elif [ $1 -eq 7 ] ; then
		CORE_PEER_LOCALMSPID="Org2BNK"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/peers/peer0.bnk.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bnk.com/users/User2@bnk.com/msp
		CORE_PEER_ADDRESS=peer1.bnk.com:7051
		PEER=PEER3

	 #Seller
	 elif [ $1 -eq 8 ] ; then
	    CORE_PEER_LOCALMSPID="Org1FTE"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/peers/peer0.app.fte.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/users/User2@app.fte.com/msp
		CORE_PEER_ADDRESS=peer0.app.fte.com:7051
		PEER=PEER0

	 #Shipper
	 elif [ $1 -eq 9 ] ; then
		CORE_PEER_LOCALMSPID="Org3SHP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/shp.com/peers/peer0.shp.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/shp.com/users/User1@shp.com/msp
		CORE_PEER_ADDRESS=peer0.shp.com:7051
		PEER=PEER5
	
	#Buyer
	 elif [ $1 -eq 10 ] ; then
	    CORE_PEER_LOCALMSPID="Org1FTE"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/peers/peer0.app.fte.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/app.fte.com/users/User1@app.fte.com/msp
		CORE_PEER_ADDRESS=peer1.app.fte.com:7051
		PEER=PEER1
	
	
	fi


	env |grep CORE
}

createChannel() {
	setGlobals 0

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.fte.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
	else
		peer channel create -o orderer.fte.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "Channel \"$CHANNEL_NAME\" is created successfully."
	echo
	echo
}



joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep $DELAY
		joinWithRetry $1
	else
		COUNTER=1
	fi
  verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3 4 5; do
		setGlobals $ch
		joinWithRetry $ch
		echo "PEER$ch joined on the channel \"$CHANNEL_NAME\"."
		sleep $DELAY
		echo
	done
}

installChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode install -n tradefinancecc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/tradecontract >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has failed."
	echo "Chaincode is installed on remote peer PEER $PEER."
	echo
}

instantiateChaincode () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -v 1.0 -c '{"Args":["init","FTE_2","FTE_B_1","FTE_S_1","SKU001","10000","1000"]}' -P "OR	('Org1FTE.member','Org2BNK.member','Org3SHP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer.fte.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -v 1.0 -c '{"Args":["init","FTE_2","FTE_B_1","FTE_S_1","SKU001","10000","1000"]}' -P "OR	('Org1FTE.member','Org2BNK.member','Org3SHP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed."
	echo "Chaincode Instantiation on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}

chaincodeQuery () {
  PEER=$1
  echo "Querying on PEER$PEER on channel '$CHANNEL_NAME'."
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  #It takes some time to synchronize across nodes, query till timeout
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["query","FTE_2"]}' >&log.txt
  done
  echo
  cat log.txt
}

chaincodeInvokeCreateLOC() {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["createLOC","FTE_2"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.fte.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["createLOC","FTE_2"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:createLOC execution on PEER$PEER failed "
	echo "Invoke:createLOC transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful. "
	echo
}

chaincodeInvokeApproveLOC () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["approveLOC","FTE_2"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.fte.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["approveLOC","FTE_2"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:approveLOC execution on PEER$PEER failed. "
	echo "Invoke:approveLOC transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
	echo
}

chaincodeInvokeInitiateShipment () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["initiateShipment","FTE_2"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.fte.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["initiateShipment","FTE_2"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:initiateShipment execution on PEER$PEER failed "
	echo "Invoke:initiateShipment transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
	echo
}

chaincodeInvokeDeliverGoods () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["deliverGoods","FTE_2"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.fte.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["deliverGoods","FTE_2"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:deliverGoods execution on PEER$PEER failed "
	echo "Invoke:deliverGoods transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
	echo
}


chaincodeInvokeShipmentDelivered () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.fte.com:7050 -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["shipmentDelivered","FTE_2"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.fte.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n tradefinancecc -c '{"Args":["shipmentDelivered","FTE_2"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke:shipmentDelivered execution on PEER$PEER failed "
	echo "Invoke:shipmentDelivered transaction on PEER $PEER on channel '$CHANNEL_NAME' is successful."
	echo
}


echo "Creating channel."
createChannel

echo "Peers joining the channel."
joinChannel


echo "Installing chaincode on Org1FTE/peer0."
installChaincode 0
echo "Installing chaincode on Org1FTE/peer1."
installChaincode 1
echo "Install chaincode on Org2BNK/peer0."
installChaincode 2
echo "Installing chaincode on Org2BNK/peer1."
installChaincode 3
echo "Installing chaincode on Org3SHP/peer0."
installChaincode 4
echo "Installing chaincode on Org3SHP/peer1."
installChaincode 5
echo

#Instantiate chaincode in one of the peers
echo "Instantiating chaincode on Org1FTE/peer1."
instantiateChaincode 1
echo

#Query chaincode on Org1FTE/peer0
echo "Querying chaincode on Org2BNK/peer0."
chaincodeQuery 2
echo

#Invoke CreateLOC by Importer Bank - Org2BNK-USER1
echo "Sending Invoke-CreateLOC transaction by Org2BNK-USER1"
chaincodeInvokeCreateLOC 6
#User1 - Importer Bank
echo

#Query on chaincode on Org2BNK/peer0
echo "Querying chaincode on Org2BNK/peer0."
chaincodeQuery 2
echo

#Exporter Bank
echo "Sending  Invoke-approveLOC by Org2BNK-USER2"
chaincodeInvokeApproveLOC 7
echo

#Query on chaincode on Org3SHP/peer0
echo "Querying chaincode on Org3SHP/peer1."
chaincodeQuery 5
echo

#Seller
echo "Sending invoke-InitiateShipment by Org1FTE-USER2."
chaincodeInvokeInitiateShipment 8
echo

#Query on chaincode on Org1FTE/peer0
echo "Querying chaincode on Org1FTE/peer0."
chaincodeQuery 0
echo

#Shipper
echo "Sending invoke-DeliverGoods by Org3SHP-USER1."
chaincodeInvokeDeliverGoods 9
#user1 - shipper
echo

#Query on chaincode on Org1FTE/peer1
echo "Querying chaincode on Org1FTE/peer1."
chaincodeQuery 1
echo

#Buyer
echo "Sending invoke-DeliverGoods by Org1FTE-USER1."
chaincodeInvokeShipmentDelivered 10
#user1 - shipper
echo

echo "Querying chaincode for final status on Org1FTE/peer1."
chaincodeQuery 1

echo
echo "Trade Finance  End to End application completed."
echo



exit 0
