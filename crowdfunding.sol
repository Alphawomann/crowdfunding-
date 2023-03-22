// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./crowdfunding.sol";

contract tech4dev{

//Create an event named launch which comprises of id, creator, gaol, starAt, endAt
event launch(
uint id, 
address indexed creator, 
uint goal, 
uint32 starAt, 
uint32 endAt
);

event cancel(
uint id
);

event pledge(
uint indexed id,
address indexed caller,
uint amount
);
//Classwork
//Create an event for Unpledge which has id, caller, amount
//Create an event for Claim whivh has an id
//Create an eveny for Refund which has an id that is not an indexed, caller and amount.
event Unpledge(uint indexed id, address indexed caller, uint amount);

event Claim(uint indexed id);

event Refund(uint id, address indexed caller, uint amount);

struct Campaign{
address creator; //address of the campaign creator 
uint goal; //the amount to be raised
uint pledged; //the amount pledged
uint32 startAt; //timestamp of when the project is starting
uint32 endAt; //timestamp of the end of the campaign
bool claimed; //true/false if the money is claimed
}
IERC20 public immutable token; //make reference to the erc20 in the interface that we created, immutable means it's not changing. It's also used to save gas

uint public count;//can stand for the total number of campaigns created and also 
// also used to generate id for the campaign

mapping (uint => Campaign) public campaigns; //mapping to capture campaign id. Make it public
mapping(uint => mapping(address => uint)) public pledgedAmount; 
//nested mapping that captures campaign id => pledger's address and the amount pledged

constructor (address _token){ //this captures the address of our token
token = IERC20 (_token); //the deployed token being saved into the 'token' declared in line 44

function Launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
require (_startAt >= block.timestamp, "startAt <now"); //the time the campaign is starting should be greater than now
require (_endAt >= _startAt, "endAt < startAt"); 
//the time it's ending should be greater than starting time
require (_endAt <= block.timestamp + 90 days, "endAt > max duration"); 
//the time it's ending should be less than 90 days

count +=1; //this is to increment the campaigns by 1. More like numbering our campaign (1,2,3,4,...)
campaigns[count] = Campaign (msg.sender, _goal, 0, _startAt, _endAt, false); 
//first thing is declaring the name of the struct, then the order of items in the struct 
//Then equate it to your mapping and inside the mapping, we'll have count inside so the campaign number can increment by one 

emit launch(count, msg.sender, _goal, _startAt, _endAt);
}

function Cancel(uint _id) external{ 
Campaign memory campaign = campaigns[_id]; 
require (campaign.creator == msg.sender, "You are not the creator");
require (block.timestamp < campaign.startAt, "The campaign has started");

delete campaigns[_id]; 
emit cancel(_id); 
}

function Pledge(uint _id, uint _amount) external{
Campaign storage campaign = campaigns[_id]; //to capture our struct and mapping
require (block.timestamp >= campaign.startAt, "campaign has not started"); 
//to be sure we're pledging to a running campaign, and not one that isn't
require (block.timestamp <= campaign.endAt, "campaign has ended"); 
//to be sure the campaign hasn't ended 

campaign.pledged += _amount; //adding an amount pledged to the campaign, capturing the total supply
pledgedAmount[_id][msg.sender] += _amount; 
//new amount pledged to the id of the campaign, also showing the msg.sender of the person calling the person calling the contracr
//the amount a person donated is mapped with the person's address and the id it was donated to
token.transferFrom (msg.sender, address(this), _amount);
//the address of the pledger, the address of the contract and the amount

emit pledge(_id, msg.sender, _amount); 
} 

function unpledge(uint _id, uint _amount) external{
Campaign storage campaign = campaigns[_id]; //to have access to our struct
require (block.timestamp <= campaign.endAt, "Campaign has ended"); //to confirm the state of the campaign i.e if it has or hasn't ended
campaign.pledged -= _amount;
pledgedAmount[_id][msg.sender] -= _amount;

token.transfer(msg.sender, _amount);
emit Unpledge(_id, msg.sender, _amount);

}

function claim(uint _id) external {
Campaign storage campaign = campaigns[_id];
require(campaign.creator == msg.sender, "You are not the creator, thieff");
//to ensure that only the campaign creator can call this function
require(block.timestamp > campaign.endAt, "campaign has ended"); 
//to confirm that the campaign has ended
require (campaign.pledged >= campaign.goal, "pledged < goal"); //to check if the goal is exceeded
require(!campaign.claimed, "campaign has been pledged"); 
//require that the campaign hasn't been claimed before

campaign.claimed = true; //set the bool to true, to allow the creator to be able to claim
token.transfer(campaign.creator, campaign.pledged); 
//this captures the transfer of pledged amount to the campaign creator
//money transferred to the campaign creator, from where? from the total amount pledged

emit Claim(_id); //broadcast to the frontend

}

function refund(uint _id) external{
Campaign memory campaign = campaigns[_id]; //using memory because we're not keeping your record again
require(block.timestamp > campaign.endAt, "It has not ended"); 
require(campaign.pledged < campaign.goal, "pledged is greater than goal");

uint balance = pledgedAmount[_id][msg.sender]; 
//capturing how much was pledged and stating the variable type
pledgedAmount [_id][msg.sender] = 0; 
//nullifying you that you don't have money with the campaign again
token.transfer(msg.sender, balance);
//the actual transfer to the person's address
emit Refund(_id, msg.sender, balance); //braodcast to the frontend
}

}



