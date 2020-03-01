pragma solidity ^0.5.3;
import "./IFreelance.sol";
import "./ERC20.sol";

/**
 * @title Freelance
 * @dev This is a freelancing platform.
 * where people can post their projects to be developed
 * developers can place their offers with details on those projects
 * project owner/publisher can assign project to developer whose offer he finds suitable
 * project's amount/price is paid by project owner in terms of an ERC-20 token, which get escrowed by contract itself
 * once developer submits project's solution, owner review it and accept/reject solution accordingly
 * in case solution accepted: escrowed amount is transfered to developer
 * in case solution rejected: escrowed amount sent back to owner and project no more assigned to that developer
 * 
 */
contract Freelance is IFreelance {
 /**
 * ERC-20 token 
 * this token is platform's primary currency in which developers get paid for their services. 
 * 
 */  
 ERC20 erc20;
 /**
  * @dev Set ERC20 contract as platform's primary token
  */
 constructor(address token) public{
     erc20 = ERC20(token);
 }
 
    struct Project{
        uint256 amount; // project price (in terms of ERC20 token)
        address owner;  // who posted project
        address assignee; // developer: to whom project is asigned
        string requirements_url; // ipfs link of documents contains details/requirements of the project to be developed
        string solution_url;  // ipfs link of solution developer developed and delivered
        bool isCompleted; // flag to track project status
       
    }
    struct Offer{
        uint256 amount; // price demanded by developer
        string url; // ipfs link of offer documents
    }
    
    // mapping( project_id => Project)
    mapping(uint256 => Project) public projects;
    
    // mapping( project_id => mapping( offerer => Offer)
    mapping(uint256 => mapping(address => Offer)) public offers;
    
  /**
    * @dev post project required to get developed
    * @param url - ipfs link of project requirements docs.
    * @param price - project price (in terms of ERC20 token).
    * @return - project id
    */
    function postProject(string calldata url, uint256  price) external returns (uint256 ) {
        uint256 id = uint(keccak256(abi.encodePacked(url))) % 10 ** 16; // project id generating from url of length 16.
        Project memory project = Project (price,msg.sender,address(0),url,"",false);
        require(projects[id].owner == address(0),"project already exists");
        projects[id] = project;
        emit ProjectPosted(id,url,msg.sender);
        return id;
        
    }
  /**
    * @dev developers can place offer on project he finds suitable
    * Modifier {isCompleted} ensures project isn't marked completed.
    * @param project_id - id of project placing offer on.
    * @param offer_url - ipfs url of offer docs.
    * @param price - price demanding for project.
    * 
    */
    function placeOffer(uint256 project_id, string calldata offer_url, uint256 price) isCompleted(project_id) external {
        require(projects[project_id].owner != address(0),"project doesn't exists");
        Offer memory offer = Offer(price,offer_url);
        require(bytes(offers[project_id][msg.sender].url).length == 0,"offer already exists");
        offers[project_id][msg.sender] = offer;
        emit OfferPlaced(project_id,offer_url,msg.sender);
        
    }
  /**
    * @dev project owner can assign project to developer whose offer he finds suitable.
    * Modifier {onlyOwner} ensuring only project's owner can assign project
    * Modifier {isCompleted} ensures project isn't marked completed.
    * @param project_id - id of project going to assign.
    * @param offerer - address of offerer to whom owner want to assign project.
    */
    function assignProject(uint256 project_id, address offerer) onlyOwner(project_id) isCompleted(project_id) external {
        require(projects[project_id].assignee == address(0),"project already assigned");
        require(bytes(offers[project_id][offerer].url).length != 0,"invalid offerer");
        projects[project_id].assignee = offerer;
        // checking if owner has approved contract for sufficient amount of tokens as per developer's offer
        require( erc20.allowance(msg.sender,address(this)) >= offers[project_id][offerer].amount,"insufficient allowance");
        // escrowing funds
       erc20.transferFrom(msg.sender,address(this),offers[project_id][offerer].amount);
        
       emit ProjectAssigned(project_id,offerer);
    }
  /**
    * @dev developer/assignee submitting solution.
    * Modifier {onlyAssignee} ensures only assignee (to whom project assigned) can submit its solution.
    * Modifier {isCompleted} ensure project isn't marked completed.
    * @param project_id - id of project whose solution is to be submitted.
    * @param solution_url - ipfs url of solution to be delivered/submitted.
    * 
    */ 
    function submitSolution(uint256 project_id, string calldata solution_url) onlyAssignee(project_id) isCompleted(project_id) external{
        require(bytes(projects[project_id].solution_url).length == 0,"solution already submitted");
        projects[project_id].solution_url = solution_url;
        
        emit SolutionSubmitted(project_id,solution_url,msg.sender);
    }
  /**
    * @dev accepting solution submitted by assignee.
    * Modifier {onlyOwner} ensures only project owner should be able to accept solution.
    * Modifier {isCompleted} ensure project isn't marked completed.
    * @param project_id - id of project whose solution is to be accepted.
    * 
    */ 
    function acceptSolution(uint256 project_id) onlyOwner(project_id) isCompleted(project_id) external {
        require(bytes(projects[project_id].solution_url).length !=0,"solution isn't submitted");
        projects[project_id].isCompleted = true;
        
        address assignee = projects[project_id].assignee;
        // releasing funds to assignee
        erc20.transfer(assignee,offers[project_id][assignee].amount);
        
        emit SolutionAccepted(project_id,projects[project_id].solution_url,projects[project_id].assignee);
    }
  /**
    * @dev rejecting solution submitted by assignee.
    * Modifier {onlyOwner} ensures only owner should be able to reject project's solution.
    * Modifier {isCompleted} ensure project isn't completed.
    * @param project_id - id of project whose solution is to be rejected.
    * 
    */ 
    function rejectSolution(uint256 project_id, string calldata remarks) onlyOwner(project_id) isCompleted(project_id) external {
        require(bytes(projects[project_id].solution_url).length !=0,"solution isn't submitted");
        string memory temp = projects[project_id].solution_url;
        address assignee = projects[project_id].assignee;
        delete projects[project_id].solution_url; // removing submitted slution from mapping.
        delete projects[project_id].assignee; // project is no more assigned to assignee whose solution is rejected.
        // releasing escrowed funds to project's owner
        erc20.transfer(projects[project_id].owner,offers[project_id][assignee].amount);
        
        emit SolutionRejected(project_id,temp,assignee, remarks);
    }
   /**
    * @dev modifier to check if caller is project's owner.
    * @param project_id - id of project whose owner is to be checked.
    * 
    */   
    modifier onlyOwner(uint256 project_id){
        require(projects[project_id].owner == msg.sender,"owner unauthorized");
        _;
    }
  /**
    * @dev modifier to check if caller is project's assignee (to whom project was assigned).
    * @param project_id - id of project whose assignee is to be checked.
    * 
    */  
    modifier onlyAssignee(uint256 project_id){
         require(projects[project_id].assignee == msg.sender,"assignee unauthorized");
         _;
    }
  /**
    * @dev modifier to check if project is already marked completed.
    * @param project_id - id of project whose completion is to be checked.
    * 
    */  
    modifier isCompleted(uint256 project_id){
        require(!projects[project_id].isCompleted ,"project marked completed");
        _;
    }

}
