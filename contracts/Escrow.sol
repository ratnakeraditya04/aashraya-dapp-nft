//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// We are using this interface to interact with our RealEstate NFT.addmod
interface IERC721 {
    // Needed to Transfer our NFT from Real Estate to here in this Escrow Contract. 
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}
contract Escrow {
    // Create Some State Variables. Will get Stored in Blockchain. 
    address public lender ; 
    address public inspector ;
    address payable public seller ; 
    address public nftAddress ; 


    // Only Buyer can access it. 
    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID] , "Only Buyer can call this method"); 
        _;
    }
    // Only Seller can access it. 
    modifier onlySeller() {
        require(msg.sender == seller, "Only Seller can do this Method"); 
        _; 
    }

    // Only Inspector can call it 
    modifier onlyInspector() {
        require(msg.sender == inspector, "Only Inspector can do this Method" ); 
        _; 
    } 

    // In all the mappings we created below we are actually linking a relation between NFT Id's and different aspects of NFT. 
    mapping(uint256 => bool) public isListed ; 
    mapping(uint256 => uint256) public purchasePrice ; 
    mapping(uint256 => uint256) public escrowAmount ;
    mapping(uint256 => address) public buyer ; 
    // Checking for inspection passed or not.  
    mapping(uint256 => bool) public inspectionPassed; 
    //  Granting and Checking Approval for the Process. 
    // Here, address is of the person who approves it or not. 
    mapping(uint256 => mapping(address => bool )) public approval ; 

    constructor(
        address _nftAddress, 
        address payable _seller, 
        address _inspector, 
        address _lender
        ) {
        nftAddress = _nftAddress ; 
        seller = _seller ;
        lender = _lender ; 
        inspector = _inspector ; 
    }

    // Listing properties.  
    function list(
        uint256 _nftId,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Moving the NFT out of the User Wallet and putting it into the Escrow.
        // Our NFT is coded in a different file(RealEstate.sol) - We need to import it.  

        // address(this) - Returns the address of this Smart Contract. 

        // Transfer NFT from seller to this contract. 
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);

        isListed[_nftId] = true ;
        purchasePrice[_nftId] = _purchasePrice ;  
        escrowAmount[_nftId] = _escrowAmount; 
        buyer[_nftId] = _buyer; 
    }

    // Earnest Money 
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]); 
    }

    // Update Inspection Status - (only Inspection) 
    function updateInspectionStatus(uint256 _nftID , bool _passed) public onlyInspector {
        inspectionPassed[_nftID] = _passed ; 
    } 

    // Approve Sale. 
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true ;
    }

    // We need to FINALIZE SALE. For this we need the following, 
    // -> Requires inspection status
    // -> Requires sale to be authorised
    // -> Requires funds to be correct amount 
    // -> Transfer NFT to buyer 
    // ->Transfer Funds to seller. 

    function finalizeSale(uint256 _nftID ) public {
        require(inspectionPassed[_nftID]); 
        require(approval[_nftID][buyer[_nftID]]); 
        require(approval[_nftID][seller]); 
        require(approval[_nftID][lender]); 
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false; 

        (bool success, ) = payable(seller).call{value: address(this).balance}(""); 
        require(success) ;

        // Transfer NFT Ownership to Buyer 
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID] , _nftID); 
    }


    // Cancel Sale (handle earnest deposit) 
    function cancelSale(uint256 _nftID) public {
        if(inspectionPassed[_nftID] == false ) {
            payable(buyer[_nftID]).transfer(address(this).balance); 
        }
        else {
            payable(seller).transfer(address(this).balance); 
        }
    }

    receive() external payable {} 
    // Retrieving Balance out here.
    function getBalance() public view returns (uint256) {
        return address(this).balance ;
    }
}
