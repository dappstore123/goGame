pragma solidity ^0.5.0;

contract GoGame {
   uint32 public N ;//棋盘格子数
    int public score;
   int[] board;
   int public blackScore;
   int public whiteScore;
   int WHITE = -1;
   int EMPTY = 0;
   int BLACK = 1;
   bool public gameOver =false;
   bool public start = false;
   address public owner; //白子
   address public challenger;//黑子
  
   uint public ownerValue;
   address public winer;
   int public winerColor;
   uint public step = 0;//
   int public toPlay;
   uint MAXSTEP;
   
   int public challengeStatus ;
   
   uint public passCount = 0;
   
   int public invert =1;
   
   bool public applyforGameOverStatus = false;
   
   uint timeOut=10;
   uint MAXTIME = 1000;
   uint public currentBlockNum;
   bool public shoudGameOverStatus;
   mapping(address => uint) public  challengerValue;
   mapping(address => int) public  players;
   mapping(int => uint) public  timer;
   mapping(int => address) public  colors;
   
     constructor (uint32 n) payable public  {
        owner = msg.sender;
        uint timestamp = block.timestamp;
        if(timestamp%2==1){
            invert = -1;
        }
        N =n;
        MAXSTEP = 2*n*n;
        toPlay = BLACK;
           
        players[owner] = WHITE*invert;
        colors[WHITE*invert] = owner;
        ownerValue = msg.value;
        timer[WHITE] = MAXTIME;
        timer[BLACK] = MAXTIME;
        

     }
     
          function getBoard() view external returns (int[] memory) {
         return board;
     }
     



     
     
     function challenge() payable external {
	    address player = msg.sender;
	    require(player != owner);
	    require(start == false);
	    require(challengeStatus == 0);
	    players[player] = BLACK*invert;
	    colors[BLACK*invert] = player;
	    challenger = player;
	    challengerValue[player] += msg.value;
	    challengeStatus = 1;
    }
    
    function challengeConfirm()  external {
	    address addr = msg.sender;
	    require(addr == owner);
	    require(start == false);
	    start = true;
	    currentBlockNum = block.number;
	    challengeStatus = 2;
    }
    
    function challengeReject()  external {
	    address addr = msg.sender;
	    require(addr == owner);
	    require(start == false);
	    require(challengeStatus == 1);
	    challengeStatus = 0;
	    delete challenger;
	    delete colors[players[challenger]];
    }
    
    function giveUpChallenge () external  {
        address addr = msg.sender;
	    require(addr == challenger);
	    require(start == false);
	    require(challengeStatus == 1);
	    challengeStatus = 0;
	    delete challenger;
        
        
        uint balance =  address(this).balance;
       if(challengerValue[addr]!= 0){
             msg.sender.transfer(challengerValue[addr]);
	        uint balanceAfter = address(this).balance;
	        require(balance>= challengerValue[addr] + balanceAfter);
       }
	 
	   delete challengerValue[addr];
	   delete colors[players[challenger]];
	   delete  players[challenger];
    }
    
    function getBackChallenge() external{
        address addr = msg.sender;
       uint balance =  address(this).balance;
       require(challengerValue[addr] > 0);
       require( challenger!= addr);
	  if(challengerValue[addr]!= 0){
             msg.sender.transfer(challengerValue[addr]);
	        uint balanceAfter = address(this).balance;
	        require(balance>= challengerValue[addr] + balanceAfter);
       }
	   
	   delete challengerValue[addr];
	   delete colors[players[challenger]];
	   delete  players[challenger];
    }
 
    function destruct()  external gamendModifier{
         address addr = msg.sender;
       require(addr == winer);
       selfdestruct( msg.sender);
    }
    
    function resign() external operateModifier gameingModifier{ 
       
        gameOver = true;
        winer = colors[toPlay*-1];
         toPlay *=-1;
    }
    
    function play(uint32 x) external operateModifier gameingModifier timeOutModifer{ 
       require(!applyforGameOverStatus);
       step +=1;
        
        //...
        
        passCount = 0;
        toPlay *=-1;
    }
    
    function passMove() external operateModifier gameingModifier timeOutModifer{
        require(!applyforGameOverStatus);
        step +=1;
        
        //...
        passCount +=1;
        if(passCount >=2){
            gameOver = true;
            updateScore();
            updateWiner ();
            
        }
    }
    function updateScore()  public  returns (int  ){
       shoudGameOverStatus = true;
       score = 100; 
       //...
    }
    
   function applyforGameOver() external operateModifier gameingModifier timeOutModifer{
       require(!applyforGameOverStatus);
        updateScore();
         toPlay *=-1;
         applyforGameOverStatus = true;
    }
    
    function confirmApplyforGameOver() external operateModifier gameingModifier timeOutModifer{
        require(applyforGameOverStatus);
        gameOver = true;
        toPlay *=-1;
        updateWiner ();
    }
    
    function rejectApplyforGameOver() external operateModifier gameingModifier timeOutModifer{
        require(applyforGameOverStatus);
        applyforGameOverStatus=false;
         toPlay *=-1;
    }
    
    function forcerGameOver() external operateModifier  gameingModifier timeOutModifer{
             updateScore();
            require(shoudGameOverStatus);
           
            gameOver = true; 
            updateWiner ();
    }
    
    function updateWiner () internal {
        if (score > 0) {
                winerColor = BLACK;
                winer = colors[BLACK];
            }else {
                 winerColor = WHITE;
                winer = colors[WHITE];
            }
    }
    

    
    modifier timeOutModifer(){
         int color=toPlay;
        uint useTime = block.number - currentBlockNum ;
        require(useTime<= timeOut);
        currentBlockNum = block.number;
        require(timer[color] > useTime );
        timer[color]= timer[color] - useTime;
         _;
    }
    
    modifier operateModifier() {
         address playerAdd = msg.sender;
        require( colors[toPlay] == playerAdd,"u can not do resignation");
         _;
    }
    
    modifier gameingModifier(){
        require(gameOver == false);
        require(start == true);
        require(step<= MAXSTEP);
         _;
    }
    
     modifier gamendModifier(){
        require(gameOver == true || start == false);
         _;
    }
     
}
