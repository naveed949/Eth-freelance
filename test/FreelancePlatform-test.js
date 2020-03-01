const FreelancePlatform = artifacts.require('Freelance')
const ERC20 = artifacts.require('TestERC20')
const truffleAssert = require('truffle-assertions')

const BN = require("bn.js")



contract('FreelancePlatform', accounts => {
  let platform
  let erc20;
  const minter = accounts[0]
  const owner = accounts[1]
  const offerer1 = accounts[2]
  const offerer2 = accounts[3]
  const offerer3 = accounts[4]
  const offerer4 = accounts[5]
  let project_id;
  before(async () => {
    erc20 = await ERC20.new()
    platform = await FreelancePlatform.new(erc20.address)
    await erc20.transfer(owner,100005,{from: minter})
  })

  it('Posting Project', async () => {
    let project_url = "http://example.com/project1.pdf"
    let price = 200;
     let tx = await platform.postProject(project_url,price,{from: owner});
    
    truffleAssert.eventEmitted(tx, 'ProjectPosted', (ev) => {
      project_id = ev.project_id.toString();
      return ev.project_url === project_url && ev.owner === owner;
  });
})
  it('Same project can\'t be posted twice', async () => {
    let project_url = "http://example.com/project1.pdf"
    let price = 200;
     truffleAssert.reverts(platform.postProject(project_url,price,{from: owner}),'project already exists')

  })
  it('Placing Offer#1', async ()=>{
    let offer_url = "http://example.com/offer1.pdf";
    let price = 150;
    let tx = await platform.placeOffer(project_id,offer_url,price,{from: offerer1});
    truffleAssert.eventEmitted(tx, 'OfferPlaced', (ev) => {
      return ev.project_id.toString() === project_id && ev.offer_url === offer_url && ev.offerer == offerer1;
  });
  })
  it('Placing Offer#2', async ()=>{
    let offer_url = "http://example.com/offer2.pdf";
    let price = 160;
    let tx = await platform.placeOffer(project_id,offer_url,price,{from: offerer2});
    truffleAssert.eventEmitted(tx, 'OfferPlaced', (ev) => {
      return ev.project_id.toString() === project_id && ev.offer_url === offer_url && ev.offerer == offerer2;
  });
  })
  it('Placing Offer#3', async ()=>{
    let offer_url = "http://example.com/offer3.pdf";
    let price = 170;
    let tx = await platform.placeOffer(project_id,offer_url,price,{from: offerer3});
    truffleAssert.eventEmitted(tx, 'OfferPlaced', (ev) => {
      return ev.project_id.toString() === project_id && ev.offer_url === offer_url && ev.offerer == offerer3;
  });
})
it('Offerer can\'t place more than one offers on same project', async ()=>{
  let offer_url = "http://example.com/offer4.pdf";
  let price = 180;
  truffleAssert.reverts(
    platform.placeOffer(project_id,offer_url,price,{from: offerer3}),'offer already exists')
  
})
  it('Owner can\'t assign project without getting funds escrowed first', async ()=>{
    truffleAssert.reverts(
      platform.assignProject(project_id,offerer1,{from: owner}),"insufficient allowance");
  })
  it('Except owner no one can assign his project', async ()=>{
    truffleAssert.reverts(
      platform.assignProject(project_id,offerer1,{from: offerer1}),'owner unauthorized');
  })
  it('Owner escrowing his funds & assigning project to offerer', async ()=>{
    let tokens = 150;
    await erc20.approve(platform.address,tokens,{from: owner});
    let funds = await erc20.allowance(owner,platform.address)
    assert.equal(funds.toString(),JSON.stringify(tokens))
    let tx = await platform.assignProject(project_id,offerer1,{from: owner});
    truffleAssert.eventEmitted(tx,'ProjectAssigned',(ev)=>{
      return ev.project_id.toString() == project_id && ev.assignee == offerer1;
    })
  })
  it('Checking if owner\'s funds were escrowed', async ()=>{
    let tokens = 150;
    let fundsEscrowed = await erc20.balanceOf(platform.address)
    assert.equal(fundsEscrowed.toString(),JSON.stringify(tokens))
  })
  it('Owner can\'t mark project completed before assignee submitting its solution', async ()=>{
  
    truffleAssert.reverts(platform.acceptSolution(project_id,{from: owner}),'solution isn\'t submitted') ;

  })
  it('Except Assignee no one can submit project\'s solution', async ()=>{
    let solution_url = 'http://example.com/solution2.rar'
    truffleAssert.reverts(platform.submitSolution(project_id,solution_url,{from: offerer2}),'assignee unauthorized') ;
   
  })
  it('Assignee submitting project\'s solution', async ()=>{
    let solution_url = 'http://example.com/solution.rar'
    let tx = await platform.submitSolution(project_id,solution_url,{from: offerer1});
    truffleAssert.eventEmitted(tx,'SolutionSubmitted',(ev)=>{
      return ev.project_id.toString() == project_id && ev.solution_url == solution_url && ev.submitter == offerer1;
    })
  })
  it('Assignee can\'t change his submitted solution', async ()=>{
    let solution_url = 'http://example.com/solution2.rar'
    truffleAssert.reverts(platform.submitSolution(project_id,solution_url,{from: offerer1}),'solution already submitted') ;

  })
  it('Except owner no one can accept/reject submitted project\'s solution', async ()=>{
    
    truffleAssert.reverts(platform.acceptSolution(project_id,{from: offerer1}),'owner unauthorized') ;
    truffleAssert.reverts(platform.rejectSolution(project_id,"solution is not as required",{from: offerer1}),'owner unauthorized') ;

  })
  it('Owner accepting project\'s solution', async ()=>{
    let solution_url = 'http://example.com/solution.rar'
    let tx = await platform.acceptSolution(project_id,{from: owner});
    truffleAssert.eventEmitted(tx,'SolutionAccepted',(ev)=>{
      return ev.project_id.toString() == project_id && ev.solution_url == solution_url && ev.submitter == offerer1;
    })
  })
  it('Checking if project\'s escrowed funds released to assignee', async ()=>{
    let reward = 150;
    let balance = await erc20.balanceOf(offerer1);
    assert.equal(balance.toString(),JSON.stringify(reward));
  })
  it('Can\'t place offers on completed project', async ()=>{
    let offer_url = "http://example.com/offer4.pdf"
    let price = 230;
    truffleAssert.reverts(platform.placeOffer(project_id,offer_url,price,{from: offerer4}),'project marked completed');

  })
  it('Owner rejecting solution & project no more assigned to that assignee & escrowed funds released back to owner', async ()=>{
    /**
     * making old project's state first
     * */ 
    // posting new project
    let project_url = 'http://example.com/project2.pdf'
    let amount = 150;
    let tx = await platform.postProject(project_url,amount,{from: owner})
    truffleAssert.eventEmitted(tx,"ProjectPosted", (ev)=>{
      project_id = ev.project_id.toString();
      return ev.project_url == project_url && ev.owner == owner;
    })
    let solution_url = 'http://example.com/solution.rar'
    let offer_url = 'http://example.com/offer1.pdf'
    let price = 120
    // placing offer
    await platform.placeOffer(project_id,offer_url,price,{from: offerer1})
    // assigning project and escrowing funds
    await erc20.approve(platform.address,price,{from: owner})
    await platform.assignProject(project_id,offerer1,{from: owner})
    // submitting project
    await platform.submitSolution(project_id,solution_url,{from: offerer1})

    let oldBalance = await erc20.balanceOf(owner)
    let escrowedAmount = price

    /**
     * rejecting solution now
     * */ 
    let remarks = 'solution not working'
    let tx2 = await platform.rejectSolution(project_id,remarks,{from: owner});
    truffleAssert.eventEmitted(tx2,'SolutionRejected',(ev)=>{
      return ev.project_id.toString() == project_id && ev.solution_url == solution_url && ev.submitter == offerer1 && ev.remarks == remarks;
    })
    let project = await platform.projects(project_id)
    assert.notEqual(project.assignee,offerer1)
    assert.notEqual(project.solution_url,solution_url)

    let newBalance = await erc20.balanceOf(owner)
     assert.equal(newBalance.toNumber(),oldBalance.toNumber() + escrowedAmount)
  })

})
