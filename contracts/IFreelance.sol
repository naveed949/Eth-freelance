pragma solidity ^0.5.3;

/** 
*
* @dev interface of Freelance platform
*/
interface IFreelance {

/**
*@dev creates new project.
* Returns 'uint256' project id indicating new project created.
* Emits a {ProjectPosted} event.
 */
function postProject(string calldata url, uint256  price) external returns (uint256 );
/**
* @dev placed new offers on projects.
* 
* Emits {OfferPlaced} event.
 */
function placeOffer(uint256 project_id, string calldata offer_url, uint256 price) external;

/**
*@dev assigns project to offerer, whose offer owner seems most suitable.
* escrow funds of owner.
* 
* Emits {ProjectAssigned} event.
 */
function assignProject(uint256 project_id, address offerer) external;

/**
* @dev Assignee submits his solution through it.
* 
* Emits {SolutionSubmitted} event.
 */
function submitSolution(uint256 project_id, string calldata solution_url) external;

/**
* @dev owner accepts solution he finds as per project's requirements.
* 
* Emits {SolutionAccepted} event.
* */

function acceptSolution(uint256 project_id) external;

/**
* @dev owner rejects solution he finds not as per project's requirements.
* Modifier {onlyOwner} ensures only owner should be able to reject project's solution.
* Modifier {isCompleted} ensure project isn't completed.
* Emits {SolutionRejected} event.
 */
function rejectSolution(uint256 project_id, string calldata remarks) external;


  /**
    * @dev Emitted when new project is posted.
    * 
    */
    event ProjectPosted(uint256 indexed project_id, string project_url, address indexed owner);
  /**
     * @dev Emitted when new offer is placed on project.
     *
     */
    event OfferPlaced( uint256 indexed project_id, string offer_url, address indexed offerer);
  /**
    * @dev Emitted when project is assigned to 'assignee'.
    * 
    */
    event ProjectAssigned(uint256 indexed project_id, address indexed assignee);
  /**
    * @dev Emitted when solution is submitted of project 'project_id' by its assignee 'submitter'.
    * 
    */
    event SolutionSubmitted(uint256 indexed project_id, string solution_url, address indexed submitter);
  /**
    * @dev Emitted when delivered solution of project with 'project_id' is accepted.
    * 
    */
    event SolutionAccepted(uint256 indexed project_id, string solution_url, address indexed submitter);
  /**
    * @dev Emitted when solution with 'solution_url' is rejected by its owner with his final 'remarks'.
    * 
    */
    event SolutionRejected(uint256 indexed project_id, string solution_url, address indexed submitter, string remarks);
    
}