const should = require('chai').should()
const ganache = require('ganache-cli').server({gasLimit: web3.utils.toHex(8e6)})
const RiftPact = artifacts.require('RiftPact')
const OathForge = artifacts.require('OathForge')
const ERC20 = artifacts.require('ERC20')
let riftPact = {}
let oathForge = {}
let erc20 = {}

ganache.listen(8545, (err, blockchain) => {
    if(err) console.error(err)
})

contract('RiftPact', accounts => {
    beforeEach(async () => {
        const totalSupply = 1e6 // 6 million erc20 tokens

        oathForge = await OathForge.new('OathForge', 'OAT')
        erc20 = await ERC20.new()

        // Create a token in the oathforge contract before deploying the riftpact
        await oathForge.mint(accounts[1], 'https://example.com', 1e3)
        const tokenId = parseInt(await oathForge.nextTokenId()) - 1
        const auctionAllowedAt = Math.floor(new Date().getTime() / 1000) + 1 // 1 second after now
        const waitAfterLastBidToCloseAuction = 10 // You have to wait 10 seconds after the last bid to close the auction
        const minIncrementPerBid = 10 // You must bid at least 1 tokens more to surpass the last bid
        riftPact = await RiftPact.new(oathForge.address, tokenId, totalSupply, erc20.address, auctionAllowedAt, waitAfterLastBidToCloseAuction, minIncrementPerBid)
    })
    it('Should deploy a new riftpact successfully', async () => {
        const tokenId = parseInt(await oathForge.nextTokenId()) - 1
        const totalSupply = 1e6 // 6 million erc20 tokens
        const erc20 = await ERC20.new()
        const auctionAllowedAt = Math.floor(new Date().getTime() / 1000) + 5 // 5 seconds after now
        const waitAfterLastBidToCloseAuction = 60 * 60 * 5 // You have to wait 5 hours after the last bid to close the auction
        const minIncrementPerBid = 100 // You must bid at least 100 tokens more to surpass the last bid

        // address __parentToken,
        // uint256 __parentTokenId,
        // uint256 __totalSupply,
        // address __currencyAddress,
        // uint256 __auctionAllowedAt,
        // uint256 __minAuctionCompleteWait,
        // uint256 __minBidDeltaPermille
        const riftPactTwo = await RiftPact.new(oathForge.address, tokenId, totalSupply, erc20.address, auctionAllowedAt, waitAfterLastBidToCloseAuction, minIncrementPerBid)

        // Check that it has been deployed
        riftPactTwo.should.have.property('address')
    })
    it('Should start an auction successfully when the allowed time is reached', async () => {
        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        timeAuctionStarted.should.not.equal(0)
    })
    it('Should bid on a started auction successfully', async () => {
        const bid = 500

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bid)
        await riftPact.submitBid(bid, { from: accounts[1] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.not.equal(1)
    })
    it('Should start an auction and bid 3 times successfully', async () => {
        const bidOne = 500
        const bidTwo = 600
        const bidThree = 700
        const bidThreeIncreased = 707

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bidOne)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[2], bidTwo)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[3], bidThree)
        await riftPact.submitBid(bidOne, { from: accounts[1] })
        await riftPact.submitBid(bidTwo, { from: accounts[2] })
        await riftPact.submitBid(bidThree, { from: accounts[3] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.equal(bidThreeIncreased)
    })
    it('Should start an auction, bid 3 times and end it successfully', async () => {
        const bidOne = 500
        const bidTwo = 600
        const bidThree = 700
        const bidThreeIncreased = 707

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bidOne)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[2], bidTwo)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[3], bidThree)
        await riftPact.submitBid(bidOne, { from: accounts[1] })
        await riftPact.submitBid(bidTwo, { from: accounts[2] })
        await riftPact.submitBid(bidThree, { from: accounts[3] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        // End auction
        await asyncSetTimeout(11) // Wait until the time between bids is reached
        await riftPact.completeAuction()
        const auctionCompletedAt = parseInt(await riftPact.auctionCompletedAt())

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.equal(bidThreeIncreased)
        auctionCompletedAt.should.not.equal(0)
    })
    it('Should increase the minBid after a small bid of 20 tokens multiplied by a minBidDeltaPermille of 10 to 21', async () => {
        const bidOne = 20
        const bidIncreased = 21

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bidOne)
        await riftPact.submitBid(bidOne, { from: accounts[1] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.equal(bidIncreased)
    })
    it('Should increase the minBid after a big bid of 3030 tokens multiplied by a minBidDeltaPermille of 10 to 3060', async () => {
        const bidOne = 3030
        const bidIncreased = 3060

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bidOne)
        await riftPact.submitBid(bidOne, { from: accounts[1] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.equal(bidIncreased)
    })
    it('Should send the payout to the latest bidder after the auction is ended', async () => {
        const bidOne = 500
        const bidTwo = 600
        const bidThree = 700
        const bidThreeIncreased = 707

        // Start the auction
        await asyncSetTimeout(2) // Wait until the auction is allowed
        await riftPact.startAuction()
        const timeAuctionStarted = parseInt(await riftPact.auctionStartedAt())

        // Bid
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[1], bidOne)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[2], bidTwo)
        await transferAndApprove(erc20, riftPact.address, accounts[0], accounts[3], bidThree)
        await riftPact.submitBid(bidOne, { from: accounts[1] })
        await riftPact.submitBid(bidTwo, { from: accounts[2] })
        await riftPact.submitBid(bidThree, { from: accounts[3] })
        const updatedMinBid = parseInt(await riftPact.minBid())

        // End auction
        await asyncSetTimeout(11) // Wait until the time between bids is reached
        await riftPact.completeAuction()
        const auctionCompletedAt = parseInt(await riftPact.auctionCompletedAt())

        // Send payout
        await riftPact.payout()

        timeAuctionStarted.should.not.equal(0)
        updatedMinBid.should.equal(bidThreeIncreased)
        auctionCompletedAt.should.not.equal(0)
    })
})

async function transferAndApprove(token, riftPactAddress, from, to, quantity) {
    const balance = parseInt(await token.balanceOf(from))
    await token.transfer(to, quantity, { from: from })
    await token.approve(riftPactAddress, quantity, { from: to })
}

function asyncSetTimeout(time) {
    console.log('Awaiting', time, 'seconds')
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve()
        }, (1e3 * time))
    })
}
