/**
 * Standalone game simulator. Use this script to compare calculated RTP values against actual returns.
 * 
 * (C)opyright 2016
 * 
 * This source code is protected by copyright and distributed under license. 
 * Please see the root LICENSE file for terms and conditions.
 * 
 */
const xxtea = require("xxtea-node");
const crypto = require ("crypto");
const filesystem = require('fs');
const color=require ("./ANSIcolor.js").code;


var defaultGame = JSON.parse(filesystem.readFileSync('./gamedef.json', 'utf8')); //default game definition (others may be loaded similarly)

var numLoops=10000000;
var currentLoop=0;
var sessionKey="";
var costPerSpin=1000; //gwei
var units=" gwei";
var walletValue=0;
var txCost=470610; //21000 gas * 22.41 gwei (July 11, 2016)
var numShares=0;
var numNoWins=0;
var sharesSpinThreshold=Math.round(txCost/costPerSpin); //how many spins to cover a transaction?
var totalTXCosts=0;
var payoutValue=0;
var clearLineEnd="                                                                  ";
var winCombinations=new Object();
var sharesCombinations=new Object();
var startTime=new Date().getTime();
var deltaTime=0;
var deltaSampleCount=0;
var remainingTime=0;

console.log(color().cursorreset);
console.log(color().clearscreen);

setTimeout(loop,1);

function loop() {
    currentLoop++;
	console.log(color().cursorreset+color().white);
	var results=generateReelResults();
	var selections=new Array();
	var stopPositions=new Array();
	for (var count=0;count<results.data.reels.length; count++) {
		var stopPos=getRandomNumber(results.data.reels[count].length-1);
		stopPositions.push(stopPos);
		selections.push(results.data.reels[count][stopPos]);
	}
	walletValue+=costPerSpin;
	var currentTime=new Date().getTime();
	deltaTime=currentTime-deltaTime;	
	if (deltaSampleCount<=0) {
		remainingTime=deltaTime*(numLoops-currentLoop);
		deltaSampleCount=20;
	}
	console.log("                   Spin "+color().yellow+(currentLoop+1)+color().white+" of "+color().yellow+numLoops+color().white+clearLineEnd);	
	console.log(color().dim+"---------------------------------------------------------------------"+color().reset);
	console.log("                Elapsed time: "+getTimeString(currentTime-startTime)+"            ");
	console.log("Estimated time to completion: "+getTimeString(remainingTime)+"            ");
	console.log(color().dim+"---------------------------------------------------------------------"+color().reset);
	console.log("Stops generated: "+stopPositions+clearLineEnd);
	var result=processGameResults(selections);	
	if (result.multiplier>0) {
		totalTXCosts+=txCost;
	}
	if (result.multiplier>0) {
		if (winCombinations[result.name]==undefined) {
			winCombinations[result.name]=0;
		}
		winCombinations[result.name]++;
	} else if (currentLoop>=sharesSpinThreshold) {		
		if (result.shares>0) {
			if (sharesCombinations[result.name]==undefined) {
				sharesCombinations[result.name]=0;
			}
			numShares+=result.shares;
			sharesCombinations[result.name]+=result.shares;
		} else {
			numNoWins++;
		}
	} else {
		numNoWins++;
	}
	console.log(color().dim+"---------------------------------------------------------------------"+color().reset);	
	console.log("Total winning combinations:"+clearLineEnd);
	for (var item in winCombinations) {		
		console.log ("   "+item+": "+winCombinations[item]+clearLineEnd);		
	}
	console.log("Total shares combinations:"+clearLineEnd);
	for (var item in sharesCombinations) {		
		console.log ("   "+item+": "+sharesCombinations[item]+" ("+Math.round((sharesCombinations[item]/numShares)*100)+"%)"+clearLineEnd);	
	}
	console.log("Total non-winning combinations:"+clearLineEnd);
	console.log("   "+numNoWins+clearLineEnd);
	console.log(color().dim+"---------------------------------------------------------------------"+color().reset);
	var RTP=roundToTwo((payoutValue/walletValue)*100);	
	console.log("   Total wallet contributions: "+walletValue+units+" (@"+costPerSpin+"/spin)"+clearLineEnd);	
	console.log("                Total payouts: "+payoutValue+units+clearLineEnd);	
	console.log("   Maximum # of shares issued: "+numShares+clearLineEnd);
	if (currentLoop>=sharesSpinThreshold) {
		console.log("Shares award spins threshhold: "+sharesSpinThreshold+clearLineEnd);	
	} else {
		console.log("Shares award spins threshhold: "+color().red+sharesSpinThreshold+color().reset+clearLineEnd);	
	}
	console.log("                          RTP: "+RTP+"%"+clearLineEnd);	
	console.log("               Total tx costs: "+totalTXCosts+units+clearLineEnd);
	console.log("                  Total costs: "+(totalTXCosts+payoutValue)+units+clearLineEnd);
	profit=walletValue-(totalTXCosts+payoutValue);
	if (profit<0) {
		console.log("                 Total profit: "+color().red+color().whiteb+profit+units+color().reset+clearLineEnd);
	} else {
		console.log("                 Total profit: "+color().black+color().whiteb+profit+units+color().reset+clearLineEnd);
	}
	if (result.multiplier>0) {
		payoutValue+=costPerSpin*result.multiplier;				
	}
	deltaTime=currentTime;
	deltaSampleCount--;
	if (currentLoop<(numLoops-1)) {
		setTimeout(loop,1);
	}
}

function roundToTwo(num) {    
    return +(Math.round(num + "e+2")  + "e-2");
}

function getTimeString(mSecs) {
    var seconds = parseInt((mSecs/1000)%60)
    var minutes = parseInt((mSecs/(1000*60))%60)
    var hours = parseInt((mSecs/(1000*60*60))%24);
	var dateStr=hours+" hours "+minutes+" minutes "+seconds+" seconds";	
	return (dateStr);
}

function getRandomNumber(maxValue) {
	var randBuff=crypto.randomBytes(4);
	var randVal=Number("0x"+randBuff.toString("hex")) % (maxValue+1);
	return (randVal);
}


function generateReelResults() {	
	var gameDefinition=defaultGame;	
	var responseData=new Object();
	responseData.data=new Object();		
	responseData.data.reels=[];
	sessionKey=generateXXTEAKey64();	
	for (var reelCount=0; reelCount<gameDefinition.reels.length; reelCount++) {
		responseData.data.reels.push([]);
		for (var stopPos=0; stopPos<gameDefinition.reels[reelCount].length; stopPos++) {		
			var randomVal=Buffer.allocUnsafe(8); //allocate 8 bytes
			crypto.randomBytes(6).copy(randomVal,0); //generate random values in last 48 bits
			randomVal.writeUInt16BE(stopPos,6); //write stop position in first 16 bits (big endian)			
			var stopPosHex=randomVal.toString("hex").toUpperCase();
			var encStopPos=encrypt(stopPosHex, sessionKey);			
			responseData.data.reels[reelCount].push(encStopPos);
		}
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
		responseData.data.reels[reelCount]=shuffle(responseData.data.reels[reelCount]);
	}	
	return(responseData);
}

/**
* Uses XXTEA to encrypt the plaintext "dataStr" string with the Base64-encoded "key64" key and returns
* the Base64-encoded result.
*/
function encrypt(dataStr, key64) {
	var key=Buffer.from(key64, "base64");
	return (Buffer(xxtea.encrypt(xxtea.toBytes(dataStr), key)).toString("base64"));
}

/**
* Uses XXTEA to decrypt the Base64-encoded "data64" string with the Base64-encoded "key64" key and
* returns the plaintext (non-encoded) string.
*/
function decrypt(data64, key64) {
	var key=Buffer.from(key64, "base64");
	var data64=Buffer.from(data64, "base64");
	return (xxtea.toString(xxtea.decrypt(data64, key)));
}

function processGameResults(selections) {
	responseData=new Object();
	responseData.data=new Object();
	var gameDefinition=defaultGame;
	////session key should be set from last round
	//var sessionKey=result[0].sessionKey;
	var stopPositions=new Array();
	var fill="";
	for (var count=0; count<selections.length; count++) {
		var encSelection=selections[count];
		var stopPosHex=decryptStopPosition(encSelection, sessionKey);
		var stopPos=parseInt("0x"+stopPosHex);
		stopPositions.push(stopPos);
		if (stopPos<10) {
			fill=" ";
		} else {
			fill="";
		}
		console.log("   stop pos for reel "+count+": "+fill+stopPos+" ("+stopPosHex+") => "+getSymbolDefinition(gameDefinition, count, stopPos).name+clearLineEnd);
	}	
	return(checkWin(stopPositions,gameDefinition));	
}

/**
* Returns the symbol definition (object) from the specified reel at the specified stop position
*/
function getSymbolDefinition(gameDefinition, reelNum, stopPosition) {
	return (gameDefinition.symbols[gameDefinition.reels[reelNum][stopPosition]]);
}

/**
* Returns a win object from the gameDefinition if it matches a winning pattern or a generated object to denote
* no win.
*/
function checkWin(stopPositions, gameDefinition) {
	var symbols=[];
	for (var count=0; count<stopPositions.length; count++) {
		symbols.push(gameDefinition.reels[count][stopPositions[count]]);
	}	
	for (count=0; count<gameDefinition.wins.length; count++) {		
		if (matchesWin(symbols, gameDefinition.wins[count].symbols)) {
			return (gameDefinition.wins[count]);
		}		
	}
	return({name:"none", "multiplier":0, "shares":0});
}

function matchesWin(chosenSymbols, winningSymbols) {
	if (chosenSymbols.length!=winningSymbols.length) {
		return (false);
	}	
	for (var count=0; count<chosenSymbols.length; count++) {		
		if (chosenSymbols[count] != winningSymbols[count]) {			
			//is symbols wildcard (match anything)?
			if (winningSymbols[count] != "x") {				
				return (false);
			}
		}
	}
	return (true); //all symbols match
}


function shuffle(input) {		
	var output=new Array();
	var indexes=crypto.randomBytes(input.length*4); //4 bytes per position since we support up to 0xFFFF reel stops
	var offset=0;
	while (input.length>0) {
		var swapIndex=indexes.readUInt16LE(offset) % input.length;
		output.push(input.splice(swapIndex,1)[0]);
		offset+=2;
	}
	return (output);		
}

function decryptStopPosition(encValue, key) {
	var hexStr=decrypt(encValue, key);	
	return(hexStr.substring(hexStr.length-4));	
}

//generate Base64-encoded random 128-bit XXTEA key
function generateXXTEAKey64() {
	return (crypto.randomBytes(16).toString("base64"));
}
