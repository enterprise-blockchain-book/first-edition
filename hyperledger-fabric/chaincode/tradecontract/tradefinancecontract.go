package main

import (
	"fmt"
	"encoding/json"
	"time"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type TradeContract struct {

}

type trade struct {
	TradeId string //used
	BuyerTaxId string //used
	Skuid string //used
	SellerTaxId string //used
	ExportBankId string // used
	ImportBankId string // used
	DeliveryDate string
    ShipperId string
	Status string // used

	TradePrice int //used
	ShippingPrice int //used

}

func (t *TradeContract) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return setupTrade(stub);
}

func (t *TradeContract) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	if function == "createLOC" {
		return t.createLOC(stub, args)
	} else if function == "approveLOC" {
	
		return t.approveLOC(stub, args)
	} else if function == "initiateShipment" {
	
		return t.initiateShipment(stub, args)
	} else if function == "deliverGoods" {
	
		return t.deliverGoods(stub, args)
	} else if function == "shipmentDelivered" {
	
		return t.shipmentDelivered(stub, args)
	} else if function == "query" {
	
		return t.query(stub, args)
	}

	return shim.Error("Invalid function name")
}

func setupTrade(stub shim.ChaincodeStubInterface) pb.Response {
	_, args := stub.GetFunctionAndParameters()
	tradeId := args[0]
	buyerTaxId := args[1]
	sellerTaxId := args[2]
	skuid := args[3]
	tradePrice,_ := strconv.Atoi(args[4])
	shippingPrice,_ := strconv.Atoi(args[5])
		
	tradeContract := trade {
		TradeId: tradeId, 
		BuyerTaxId: buyerTaxId, 
		SellerTaxId: sellerTaxId, 
		Skuid: skuid,
		TradePrice: tradePrice,
		ShippingPrice: shippingPrice,
		Status: "Trade initiated"}

	tcBytes, _ := json.Marshal(tradeContract)
	stub.PutState(tradeContract.TradeId, tcBytes)
	
	return shim.Success(nil)
}

func (t *TradeContract) createLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	tcBytes, _ := stub.GetState(tradeId)
	tc := trade{}
	json.Unmarshal(tcBytes, &tc)

	if (tc.Status == "Trade initiated") {
		tc.ImportBankId = "BNK_I_1"
		tc.Status = "LOC created"
	} else {
		fmt.Printf("Trade not initiated yet")
	}

	tcBytes, _ = json.Marshal(tc)
	stub.PutState(tradeId, tcBytes)
	
	return shim.Success(nil)
}

func (t *TradeContract) approveLOC(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if (tc.Status == "LOC created") {
		tc.ExportBankId = "BNK_E_1"
		tc.Status = "LOC approved"
	} else {
		tc.Status = "Error"
		fmt.Printf("LOC not found")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}
	
func (t *TradeContract) initiateShipment(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if (tc.Status == "LOC approved") {
		//tc.DeliveryDate = "2017-10-31"
		//set date to one month from as per contract
		current := time.Now()
		current = current.AddDate(0,1,0)
		tc.DeliveryDate = current.Format("01-02-2006")

		tc.Status = "Shipment initiated"
	} else {
		fmt.Printf("LOC not found")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	
	return shim.Success(nil)
}

func (t *TradeContract) deliverGoods(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if (tc.Status == "Shipment initiated") {
		tc.ShipperId = "SHP_1"
		tc.Status = "BOL created"
	
	} else {
		fmt.Printf("Shipment not initiated yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	
	return shim.Success(nil)
}

func (t *TradeContract) shipmentDelivered(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	tradeId := args[0]
	tcBytes, err := stub.GetState(tradeId)
	tc := trade{}
	err = json.Unmarshal(tcBytes, &tc)
	if err != nil {
		return shim.Error(err.Error())
	}

	if (tc.Status == "BOL created") {
		tc.Status = "Trade completed"
		fmt.Printf("Trade complete")
	} else {
		fmt.Printf("BAL not created yet")
	}

	tcBytes1, _ := json.Marshal(tc)
	err = stub.PutState(tradeId, tcBytes1)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(tradeId, tcBytes1)
	
	return shim.Success(nil)
}


func (t *TradeContract) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var A string // Entities
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting name of the person to query")
	}

	A = args[0]

	// Get the state from the ledger
	Avalbytes, err := stub.GetState(A)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil trade for " + A + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(Avalbytes)
}

func main() {

	err := shim.Start(new(TradeContract))
	if err != nil {
		fmt.Printf("Error creating new Trade Contract: %s", err)
	}
}
	
