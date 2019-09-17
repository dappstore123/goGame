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
   
   event challengeEvent(address addr,uint value);
   event challengeConfirmEvent(address addr,address challenger);
   event challengeRejectEvent(address addr,address challenger);
   event giveUpChallengeEvent(address addr,uint value);
   event getBackChallengeEvent(address addr,uint value);
   event destructEvent(address addr,uint value);
   event resignEvent(address addr,int color);
   event playEvent(address  addr,int color ,uint32 x); 
   event passMoveEvent(address  addr,int color);
   event applyforGameOverEvent(address  addr,int color);
   event confirmApplyforGameOverEvent(address  addr,int color);
   event rejectApplyforGameOverEvent(address  addr,int color);
   event forcerGameOverEvent(address  addr,int color);
   
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
	    emit challengeEvent(player,msg.value);
    }
    
    function challengeConfirm()  external {
	    address addr = msg.sender;
	    require(addr == owner);
	    require(start == false);
	    start = true;
	    currentBlockNum = block.number;
	    challengeStatus = 2;
	    emit challengeConfirmEvent(addr,challenger);
    }
    
    function challengeReject()  external {
	    address addr = msg.sender;
	    require(addr == owner);
	    require(start == false);
	    require(challengeStatus == 1);
	    challengeStatus = 0;
	    emit challengeRejectEvent(addr,challenger);
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
	    emit giveUpChallengeEvent(addr,challengerValue[addr]);
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
	   emit getBackChallengeEvent(addr,challengerValue[addr]);
	   delete challengerValue[addr];
	   delete colors[players[challenger]];
	   delete  players[challenger];
    }
 
    function destruct()  external gamendModifier{
         address addr = msg.sender;
       require(addr == winer);
       emit destructEvent(addr,address(this).balance);
       selfdestruct( msg.sender);
    }
    
    function resign() external operateModifier gameingModifier{ 
       emit resignEvent(msg.sender,toPlay);
        gameOver = true;
        winer = colors[toPlay*-1];
         toPlay *=-1;
    }
    
    function play(uint32 x) external operateModifier gameingModifier timeOutModifer{ 
       require(!applyforGameOverStatus);
       emit playEvent(msg.sender,toPlay,x);
       step +=1;
        
        //...
        
        passCount = 0;
        toPlay *=-1;
    }
    
    function passMove() external operateModifier gameingModifier timeOutModifer{
        require(!applyforGameOverStatus);
        emit passMoveEvent(msg.sender,toPlay);
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
       emit applyforGameOverEvent(msg.sender,toPlay);
        updateScore();
         toPlay *=-1;
         applyforGameOverStatus = true;
    }
    
    function confirmApplyforGameOver() external operateModifier gameingModifier timeOutModifer{
        require(applyforGameOverStatus);
        emit confirmApplyforGameOverEvent(msg.sender,toPlay);
        gameOver = true;
        toPlay *=-1;
        updateWiner ();
    }
    
    function rejectApplyforGameOver() external operateModifier gameingModifier timeOutModifer{
        require(applyforGameOverStatus);
        emit rejectApplyforGameOverEvent(msg.sender,toPlay);
        applyforGameOverStatus=false;
         toPlay *=-1;
    }
    
    function forcerGameOver() external operateModifier  gameingModifier timeOutModifer{
             updateScore();
            require(shoudGameOverStatus);
           emit forcerGameOverEvent(msg.sender,toPlay);
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
