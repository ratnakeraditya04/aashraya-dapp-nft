// An Assertion Library. 
const { expect } = require('chai');
const { ethers } = require('hardhat');

// Helps in Converting Currency to Tokens. 
const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

describe('Escrow', () => {
    let buyer , seller, inspector , lender ; 
    let realEstate, escrow ;

    beforeEach(async () => {
        // Set Up Accounts

        //  A Signer inEthers.js is an object that represents an Ethereum Account. 
        // Using Ethers.getSigners we are getting a list of accounts we are connected in the Hardhat Network. 
        // const signers = await ethers.getSigners() ;
        // const buyer = signers[0]; 
        // const seller = signers[1]; 
        // console.log(signers.length);
        
        
        [buyer , seller, inspector, lender] = await ethers.getSigners() ;


        // Deploy Real Estate 
        const RealEstate = await ethers.getContractFactory('RealEstate'); 
        realEstate = await RealEstate.deploy(); 

        // Mint 
        let transaction = await realEstate.connect(seller).mint("https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/1.json");
        await transaction.wait() ;
        // console.log(realEstate.address); 


        // Checking the ESCROW contract 
        const Escrow = await ethers.getContractFactory('Escrow'); 
        escrow = await Escrow.deploy(
            realEstate.address, 
            seller.address, 
            inspector.address, 
            lender.address
        ); 

        // Approve Property 
        transation = await realEstate.connect(seller).approve(escrow.address, 1) ;
        await transaction.wait() ; 

        // List Property 
        transaction = await escrow.connect(seller).list(1 , buyer.address , tokens(10) , tokens(5));  
        await transaction.wait() ;

    }) 
    describe('Deployment', () => {

        it('Returns NFT address' , async() => {
            const result = await escrow.nftAddress(); 
            expect(result).to.be.equal(realEstate.address);
        })

        
        it('Returns seller address' , async() => {
            const result = await escrow.seller() ;
            expect(result).to.be.equal(seller.address);
        })

        
        it('Returns inspector address' , async() => {  
            const result = await escrow.inspector();
            expect(result).to.be.equal(inspector.address);
        })  

        
        it('Returns lender address' , async() => {
            const result = await escrow.lender() ;
            expect(result).to.be.equal(lender.address);
        })
    })



    describe('Listing' , async () => {
        it('Updates as Listed' , async () => {
            const result = await escrow.isListed(1); 
            expect(result).to.be.equal(true); 
        })

        it('Update the Ownership' , async () => {
            // ownerOf comes from the imported openZeppelin contract. 
            // In order to move the nft from the wallet to the escrow contract, we need the permission of Owner of that NFT. 
            // So in order to do it, we need to call approve function by the owner then only we will be able to transfer. 
            expect(await realEstate.ownerOf(1)).to.be.equal(escrow.address); 
        })

        it('Returns Buyer', async() => {
            const result = await escrow.buyer(1);
            expect(result).to.be.equal(buyer.address); 
        })

        it('Returns Purchase Price', async() => {
            const result = await escrow.purchasePrice(1);
            expect(result).to.be.equal(tokens(10)); 
        })


        it('Returns Escrow Amount', async() => {
            const result = await escrow.escrowAmount(1);
            expect(result).to.be.equal(tokens(5)); 
        })
    })

    describe('Deposits' , async () => {
        it('updates contract balance' , async () => {
            const transaction = await escrow.connect(buyer).depositEarnest(1 , {value : tokens(5)});
            await transaction.wait() ;
            const result = await escrow.getBalance() ;
            expect(result).to.be.equal(tokens(5)); 
        })
    })

    describe('Inspection' , async () => {
        it('Updates Inspection Status' , async () => {
            const transaction = await escrow.connect(inspector).updateInspectionStatus(1 , true);
            await transaction.wait() ;
            const result = await escrow.inspectionPassed(1) ;
            expect(result).to.be.equal(true); 
        })
    })

    describe('Approval' , async () => {
        it('Updates Approval Status' , async () => {
            let txn1 = await escrow.connect(buyer).approveSale(1);
            await txn1.wait() ;

            let txn2 = await escrow.connect(seller).approveSale(1);
            await txn2.wait() ;

            let txn3 = await escrow.connect(lender).approveSale(1);
            await txn3.wait() ;

            expect(await escrow.approval(1 , buyer.address)).to.be.equal(true) ;
            expect(await escrow.approval(1 , seller.address)).to.be.equal(true) ;
            expect(await escrow.approval(1 , lender.address)).to.be.equal(true) ;
        })
    })


    describe('Sale' , async () => {
        beforeEach(async () => {
            let transaction = await escrow.connect(buyer).depositEarnest(1 , {value : tokens(5)}); 
            await transaction.wait(); 

            transaction = await escrow.connect(inspector).updateInspectionStatus(1 , true); 
            await transaction.wait() ;

            transaction = await escrow.connect(buyer).approveSale(1) ; 
            await transaction.wait() ;

            transaction = await escrow.connect(seller).approveSale(1) ;
            await transaction.wait() ;

            transaction = await escrow.connect(lender).approveSale(1) ;
            await transaction.wait() ;


            await lender.sendTransaction({to : escrow.address , value : tokens(5)});
            
            transaction = await escrow.connect(seller).finalizeSale(1); 
            await transaction.wait() ; 
        })
        
        // Transfers NFT Ownership of the buyer. 
        it('Updates ownership' , async () => {
            expect(await realEstate.ownerOf(1)).to.be.equal(buyer.address); 
        });

        it('Updates balance' , async () => {
            expect(await escrow.getBalance()).to.be.equal(0); 
        });
    })
})
