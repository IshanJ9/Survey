// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./survey.sol";

contract SurveyFactory {
    address[] public surveys;
    mapping(string => address) public AllSurveys;
    mapping(address=>address) public SurveyOwners;
    event SurveyCreated(address indexed surveyAddress, address indexed owner);    


    function createSurvey( string memory surveyName, uint256 pricePerResponse ) public payable {
        // Deploy the new Survey contract
        require(AllSurveys[surveyName]==address(0),"A survey with the same name exists. Please choose another name.");
        Survey survey = new Survey(msg.sender, surveyName, msg.value, pricePerResponse);        
        surveys.push(address(survey));
        AllSurveys[surveyName] = address(survey);
        SurveyOwners[address(survey)] = msg.sender;
            emit SurveyCreated(address(survey), msg.sender);
    }

    function addQuestions( string memory surveyName, string[] memory questionTexts, bool[] memory isMCQ, string[][] memory options ) public {
        address surveyAddress = getSurveyAddress(surveyName);
        Survey survey = Survey(surveyAddress);
        require(msg.sender == SurveyOwners[surveyAddress], "Only the owner can call this function");
        for (uint256 i = 0; i < questionTexts.length; i++) {
            if (isMCQ[i]) {
                require(
                    options[i].length > 0,
                    "MCQ question must have options"
                );
            }
            
            // Assuming your Survey contract has a function addQuestion that takes the parameters
            survey.addQuestion(questionTexts[i], isMCQ[i], options[i]);
        }

    }


    //Function to get the struct Questions from that survey
    function getSurveyQuestions(string memory surveyName) public view returns ( string[] memory questionTexts, bool[] memory isMCQs, string[][] memory allOptions)
    {
        address surveyAddress = getSurveyAddress(surveyName);
        Survey survey = Survey(surveyAddress);
        return survey.getQuestions();
    }

    //Functions to get the questions only
    function getSurveyQuestionTexts(string memory surveyName) public view returns (string[] memory) {
        address surveyAddress = getSurveyAddress(surveyName);
        Survey survey = Survey(surveyAddress);
        return survey.getQuestionTexts();
    }

    function getSurveyAddress(string memory surveyName) public view returns(address){
        return AllSurveys[surveyName];
    }

    function getRemainingAmount(string memory surveyName) public view returns (uint256)
    {
        address surveyAddress = getSurveyAddress(surveyName);
        Survey survey = Survey(surveyAddress);
        return survey.returnRemAmt();
    }
    
}