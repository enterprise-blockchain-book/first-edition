//Crowd Funding Contract
//For more details, refer to the book - Enterprise Blockchain - A Definitive Handbook
pragma solidity ^0.4.11;


contract CrowdFunding {
    
    
    //Funding project details
    struct FundingProject{
        
        string name;
        string email;
        string website;
        uint minimumfunds;
        uint amountraised;
        address owner;
        string status;
        
        
    }
    
    //Funder who funds project.
    struct Funder {
        string name;
        address fundedby;
        uint amount;
    }
    
    //Multiple funders can fund project
    Funder[] public funders;
    
    //Instance
    FundingProject public fundingproject;
    
	
	//String comparison utility
    function stringsEqual(string _a, string _b) internal pure returns (bool) {
		
		//temp allocation
		bytes memory a = bytes(_a);
		bytes memory b = bytes(_b);
		
		if (a.length != b.length)
			return false;
		for (uint i = 0; i < a.length; i ++)
			if (a[i] != b[i])
				return false;
		return true;
	}

   
 
    // function CrowdFunding  ( -- Defining constructors as functions with the same name as the contract is deprecated from solidity release 0.4.23
    // use function prior to 0.4.23, else use the constructor definition
    constructor (
        
        string _name,
        string _email,
        string _website,
        uint _minimumfunds,
        address _owner
      
        
        ) public
    {
        
       	
      	//convert to ether
        uint minimumfunds = _minimumfunds * 1 ether;
    	// note: etherum wallet displays currency as wei i.e 1 ether =  1000000000000000000
        uint amountraised = 0;
       
        fundingproject = FundingProject(_name,_email,_website,minimumfunds,amountraised,_owner,"Funding Started");
       
    }
    
    
    function fundProject( string name) public payable {
    
     
    if (stringsEqual(fundingproject.status ,"Funding Completed")) revert();
    	 
    funders.push(Funder({
                name: name,
      		    fundedby: msg.sender,
        		amount: msg.value
               }) 
            );
     fundingproject.amountraised =   fundingproject.amountraised + msg.value ;
     
     
     if (fundingproject.amountraised >= fundingproject.minimumfunds) {
     
     
     			 if(!fundingproject.owner.send(fundingproject.amountraised )) revert();
            
    		 	 //Transfer funds if the funding requirement is met
    		 	 fundingproject.status = "Funding Completed";
    		 
    		 } 
    else {		   
            	fundingproject.status = "In Progress";

		}
		
	
    }
    
   
    
     //This method can be called by scheduler/timer also or explicitly through an external app.
    function  stopFundRaising() public payable {
    
    
    	 if (stringsEqual(fundingproject.status ,"Funding Completed")) revert();
    	 
    	 fundingproject.status = "Funding Stopped";
    	 
    	 //return money to all funders
    	 
    	 for (uint p = 0; p < funders.length; p++) {
    	 
    	 	if(!funders[p].fundedby.send(funders[p].amount)) revert();
    	 
    	 
    	 }
    	 fundingproject.amountraised = 0;
    	
   
    
    }
    
    
    function getProjectStatus() public constant returns(string) {
    	return (fundingproject.status);
	}
    
    }
