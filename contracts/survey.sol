// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract Survey {
    address public owner;
    string public surveyName;
    uint256 public immutable totalAmount;
    uint256 public priceRemaining;
    uint256 public pricePerResponse;
    
    
    //Survey state and modifier
    enum SurveyState { Active, Completed }
    SurveyState public state;

    modifier surveyOpen() {
        require(state == SurveyState.Active, "Survey is not active");
        _;
    }


    //question structure and its array
    struct Question {
            string questionText;
            bool isMCQ; // Replaced enum with a boolean
            string[] options; // Only for MCQs
        }
    
    Question[] public questions;
    

    //Functions to get the questions only
    function getQuestionTexts() public view returns (string[] memory) {
        string[] memory questionTexts = new string[](questions.length);

        for (uint256 i = 0; i < questions.length; i++) {
            questionTexts[i] = questions[i].questionText;
        }

        return questionTexts;
    }


    //Function to get the struct Questions from that survey
    function getQuestions() public view returns (
        string[] memory questionTexts,
        bool[] memory isMCQs,
        string[][] memory allOptions
    ){
        uint256 length = questions.length;
        questionTexts = new string[](length);
        isMCQs = new bool[](length);
        allOptions = new string[][](length);

        for (uint256 i = 0; i < length; i++) {
            questionTexts[i] = questions[i].questionText;
            isMCQs[i] = questions[i].isMCQ;
            allOptions[i] = questions[i].options;
        }
    }


    //Keeping track of those who have responded
    mapping(address => bool) public hasResponded;
    //Logging the respondents
    //Have to choose one of the above approach
    event Responded(address respondent);

    constructor(address _owner, string memory _surveyName, uint256 _totalAmount, uint256 _pricePerResponse) {
        //Necessary checks for creating new survey
        require(_totalAmount > 0, "Total amount should be greater than 0");
        require(_totalAmount > _pricePerResponse, "Total amount should be greater than price per response");


        //Iniatilising every state variable
        surveyName = _surveyName;
        owner = _owner;
        totalAmount = _totalAmount;
        priceRemaining = _totalAmount;
        pricePerResponse = _pricePerResponse;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function addQuestion(
        string memory _questionText,
        bool _isMCQ, // Boolean for question type
        string[] memory _options ) public onlyOwner {
        if (_isMCQ) {
            require(_options.length > 0, "MCQ must have options");
        }

        questions.push(Question(_questionText, _isMCQ, _options));
    }

    function respond(string[] memory _answers) public payable {
        require(!hasResponded[msg.sender], "You have already responded");
        require(msg.value >= pricePerResponse, "Insufficient payment");
        require(_answers.length == questions.length, "Incomplete answers");

        hasResponded[msg.sender] = true;

        emit Responded(msg.sender);
    }

    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: pricePerResponse}("");
        require(success, "Call failed");
    }


    function checkAndUpdateState() internal {
        if (state == SurveyState.Active) {
            if (priceRemaining < pricePerResponse) {
                state = SurveyState.Completed;
            }
        }
    }

    function updateRemAmt() internal {
        priceRemaining -= pricePerResponse;
    }

    function returnRemAmt() external view returns(uint256 remAmt){
        return priceRemaining;
    }
}