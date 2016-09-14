/**
* 
* Main CypherSlot host (server) script.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
* Prior to first execution, MongoDB, Ethereum, and optionally Tor, should be installed. After this the following
* modules should be installed via NPM:
*
* npm install xxtea-node
* npm install mongodb
* npm install request
* npm install web3
*
* (would be better to include them as standalone js files in the future)
*
* This script must be run as administrator in order to enable Ethereum web3 functionality!
*
* e.g. sudo node server.js
*/
const serverVersion="0.1";

const xxtea = require("xxtea-node");
const http = require("http");
const request=require("request");
const crypto = require ("crypto");
const database = require("./database.js");
const Web3 = require('web3');
const filesystem = require('fs');
const color=require ("./ANSIcolor.js").code;

const PORT=8080;
const requiredThresholdSpins=720;
const EthRPCAddress="http://localhost:8545";
var payoutWallet=""; //Ethereum address of wallet to be used for payouts; must be unlocked manually prior to use!

var web3=new Web3(); //be sure to run this script in admin mode! (e.g. sudo node server.js)
//http.get(EthRPCAddress, (result) => {
var provider=new web3.providers.HttpProvider(EthRPCAddress);
web3.setProvider(provider);

var serverStatus="ready"; //"ready", "busy" (temporary), "maintenance" (indefinite)


var gameDefinitions = new Array();
gameDefinitions.push(JSON.parse(filesystem.readFileSync('./gamedef.json', 'utf8'))); //default game definition (others may be loaded similarly)
var totalGameShares = new Object(); //all shares issued for a specific game. eg. totalGameShares[gameID]
var activeGameShares = new Object(); //active (payable/over threshold) shares issued for a specific game. eg. activeGameShares[gameID]

database.onConnect(onDatabaseConnect);

console.log(color().whiteb+color().black+"CypherSlot Server "+serverVersion+color().reset);

console.log(color().green+"Using Ethereum Web3 endpoint at "+ color().yellow+EthRPCAddress+color().reset);

//Dynamic in-memory objects
var _wallets=new Array();
var _faucets=new Array();


var lSD_g=loadStartupData();
lSD_g.next();

function onDatabaseConnect() {	
	lSD_g.next(lSD_g);	
}

function *loadStartupData() {
	var generator=yield;
	console.log(" ");
	console.log(color().green+"Loading in-memory wallets:"+color().reset);	
	var result=yield database.find("wallets", {}, generator);		
	for (var count=0; count<result.length; count++) {
		_wallets.push(result[count]);
		console.log(color().cyan+"   #"+count+": "+color().yellow+JSON.stringify(result[count])+color().reset);
	}
	console.log(" ");
	console.log(color().green+"Loading in-memory faucets:"+color().reset);	
	result=yield database.find("faucets", {}, generator);		
	for (count=0; count<result.length; count++) {
		_faucets.push(result[count]);
		console.log(color().cyan+"   #"+count+": "+color().yellow+JSON.stringify(result[count])+color().reset);
	}	
	console.log(" ");	
	result=yield database.find("accounts", {}, generator);		
	for (count=0; count<result.length; count++) {
		var currentResult=result[count];
		if ((currentResult.games!=null) && (currentResult.games!=undefined)) {
			for (var gameCount in currentResult.games) {
				var currentGame=currentResult.games[gameCount];
				if ((totalGameShares[gameCount]==undefined) || (totalGameShares[gameCount]==null)) {
					totalGameShares[gameCount]=0;
				}
				if ((activeGameShares[gameCount]==undefined) || (activeGameShares[gameCount]==null)) {
					activeGameShares[gameCount]=0;
				}
				totalGameShares[gameCount]+=currentGame.shares;
				if (currentGame.thresholdSpins >=requiredThresholdSpins) {
					activeGameShares[gameCount]++;
				}				
			}
		}
	}
	for (var item in totalGameShares) {
		console.log(color().cyan+"   Total shares issued for game ID \""+color().white+item+color().cyan+"\": "+color().yellow+totalGameShares[item]+color().reset);
		console.log(color().cyan+"  Active shares issued for game ID \""+color().white+item+color().cyan+"\": "+color().yellow+activeGameShares[item]+color().reset);
	}
	console.log(" ");	
}

function getGameDefByID(ID) {	
	for (var count=0; count<gameDefinitions.length; count++) {
	   var currentDefinition=gameDefinitions[count];
	   if (currentDefinition.ID==ID) {		   
		   return (currentDefinition);
	   }
	}
	return (null);
}

function syncAllWallets() {
	console.log(color().yellow+"Synchronizing all wallets...");
	for (var count=0; count<_wallets.length; count++) {
	}
}

/**
* Has enough time elapsed for the in-memory wallet object to be used with the in-memory faucet object?
*/
function faucetReady(walletObj, faucetObj) {
	if ((walletObj.faucetTimes==undefined) || (walletObj.faucetTimes==undefined)) {
		//no faucet data defined
		return (true);
	}		
	for (var count=0; count<walletObj.faucetTimes.length; count++) {
		if (walletObj.active == false) {
			return (false);
		}
		if (walletObj.faucetTimes[count]._id == faucetObj._id) {
			var dateObj=new Date(walletObj.faucetTimes[count].dateTime);			
			if ((Date.now()-dateObj.getTime()) >= faucetObj.timeLimit) {
				return (true);
			} else {
				return (false);
			}
		}
	}
	//entry for faucet not found
	return (true);
}

/*
* Set the current date/time in the specified wallet for the associated faucet (e.g. when faucet funds for wallet are claimed). This
* will cause the faucet to become unavailable for the wallet until the specified faucet time limit has elapsed.
*
* Any missing structures are automatically created.
*/
function setWalletFaucetTime(walletObj, faucetObj) {
	if ((walletObj.faucetTimes==undefined) || (walletObj.faucetTimes==null)) {
		walletObj.faucetTimes=[];
	}
	var dateObj=new Date();
	for (var count=0; count<walletObj.faucetTimes.length; count++) {
		if (walletObj.faucetTimes[count]._id==faucetObj._id) {			
			walletObj.faucetTimes[count].dateTime = dateObj.toISOString();
			return;
		}
	}
	//no matching faucet ID found so create one
	walletObj.faucetTimes.push({_id:faucetObj._id, dateTime:dateObj.toISOString()});
}

function getFaucetById(ID) {
	for (var count=0; count<_faucets.length; count++) {
		if (_faucets[count]._id==ID) {
			return (_faucets[count]);
		}
	}
	return (null);
}

function getWalletById(ID) {
	for (var count=0; count<_wallets.length; count++) {
		if (_wallets[count]._id==ID) {
			return (_wallets[count]);
		}
	}
	return (null);
}

/**
* Stores the faucet object to the database.
*/
function storeFaucet(faucetObj) {
	database.update("faucets", {_id:faucetObj._id}, faucetObj);
}

/**
* Stores the wallet object to the database.
*/
function storeWallet(walletObj) {
	if ((walletObj.faucetTimes==null) || (walletObj.faucetTimes==undefined)) {
		walletObj.faucetTimes=[];
	}
	database.update("wallets", {_id:walletObj._id}, {balance:walletObj.balance, faucetTimes:walletObj.faucetTimes});
}

/**
* Returns an object containing an available "faucet"+"wallet" combination (in-memory object references); that is, a faucet that is available to be used
* with the associated wallet. If no available faucet/wallet combinations are found, null is returned.
*/
function getAvailableFaucetInfo() {
	for (var wCount=0; wCount<_wallets.length; wCount++) {
		for (var fCount=0; fCount<_faucets.length; fCount++) {
			if (_wallets[wCount].type==_faucets[fCount].type) {
				if (faucetReady(_wallets[wCount], _faucets[fCount])) {
					return ({wallet:_wallets[wCount], faucet:_faucets[fCount]});
				}
			}
		}
	}
	//none available!
	error ("no wallets are available for use with associated faucets at this time");
	return (null);
}

//request: https://nodejs.org/api/http.html#http_class_http_incomingmessage
//response: https://nodejs.org/api/http.html#http_class_http_serverresponse
function handleHTTPRequest(request, response){	
	//only headers received at this point so read following POST data in chunks...
	if (request.method == 'POST') {  
		var postData=new String();
		request.on('data', function(chunk) {
			//reading message body...
			if ((chunk!=undefined) && (chunk!=null)) {
				postData+=chunk;
			}
		});		
		request.on('end', function() {		  
			//message body fully read			
			processRequest(postData, request, response)
		});
	 }    
}

//Tor .onion service should be bound to the same port
var server = http.createServer(handleHTTPRequest);
server.listen(PORT, function(){    
    console.log(color().green+"HTTP Server listening on port "+color().yellow+PORT+color().reset);
});

function requestLog(requestType, account, ip) {
	var dateObj=new Date();
	var logStr=color().cyan+dateObj.toISOString()+color().reset;
	logStr+=color().blue+" => "+color().yellow+requestType;
	if ((account!=undefined) && (account!=null)){
		logStr+=color().blue+" => "+color().green+account;
	}
	logStr+=color().magenta+" ["+ip+"]";
	logStr+=color().reset;
	console.log(logStr);
}

function requestError(requestType, errMsg, ip) {
	var dateObj=new Date();
	var logStr=color().cyan+dateObj.toISOString()+color().reset;
	logStr+=color().blue+" => "+color().red+requestType+" (!)\n   "+errMsg+color().reset;	
	logStr+=color().magenta+" ["+ip+"]";
	console.log(logStr);
}

function error(errMsg) {	
	var logStr="   "+errMsg+color().reset;		
	console.log(logStr);
}

function processRequest(postData, request, response) {
	var requestObj=JSON.parse(postData);
	var responseData=new Object();
	responseData.response=requestObj.request;
	responseData.msgID=requestObj.msgID;
	if ((requestObj.gameID!=null) && (requestObj.gameID!=undefined) && (requestObj.gameID!="")) {
		var gameDef=getGameDefByID(requestObj.gameID)
		responseData.gameID=requestObj.gameID;
	}
	responseData.serverVersion = serverVersion;
	if (requestObj.data!=undefined) {
		if (requestObj.data.account!=undefined) {
			responseData.account=requestObj.data.account;
		}
	}
	switch (String(requestObj.request).toLowerCase()) {
		case "status": 
			requestLog("status", null, request.connection.remoteAddress);
			responseData.status=serverStatus;			
			response.end(JSON.stringify(responseData));
			break;
		case "balance":
			requestLog("balance", requestObj.data.account, request.connection.remoteAddress);			
			var gAB_g=getAccountBalance(requestObj.data, responseData, response);
			gAB_g.next(); //start generator
			gAB_g.next(gAB_g); //pass in reference to self
			break;
		case "genreelres": 
			requestLog("genreelres", requestObj.data.account, request.connection.remoteAddress);			
			var gRR_g=generateReelResults(requestObj.data, responseData, response, gameDef);
			gRR_g.next();
			gRR_g.next(gRR_g);
			break;
		case "select": 
			requestLog("select", requestObj.data.account, request.connection.remoteAddress);			
			var pGR_g=processGameResults(requestObj.data, responseData, response, gameDef);
			pGR_g.next();
			pGR_g.next(pGR_g);
			break;
		case "getfaucet": 
			requestLog("getfaucet", requestObj.data.account, request.connection.remoteAddress);
			var wfInfo=getAvailableFaucetInfo();			
			if (wfInfo!=null) {				
				//sanitize objects before returning data
				console.log("   available wallet: "+wfInfo.wallet.address);
				console.log("   available faucet: "+wfInfo.faucet._id);
				responseData.data=wfInfo;
				response.end(JSON.stringify(responseData));
			} else {				
				responseData.data=null; //better way to handle this?
				response.end(JSON.stringify(responseData));
			}
			break;
		case "shareholderinfo": 
			requestLog("shareholderinfo", requestObj.data.account, request.connection.remoteAddress);
			var gSI_g=getShareholderInfo(requestObj.data, responseData, response, gameDef);
			gSI_g.next();
			gSI_g.next(gSI_g);
			break;
		case "claim": 
			requestLog("claim", requestObj.data.account, request.connection.remoteAddress);
			var cFA_g=claimFaucetAmount(requestObj.data, responseData, response);
			cFA_g.next();
			cFA_g.next(cFA_g);
			break;
		default: 
			requestError(requestObj.request, postData, request.connection.remoteAddress);
			responseData.data="unrecognized request type";
			response.end(JSON.stringify(responseData));
			break;
	}	
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

function* claimFaucetAmount(requestData, responseData, response) {
	var generator=yield;
	responseData.data=new Object();	
	var faucetObj=requestData.faucet;	
	var faucet=getFaucetById(faucetObj._id); //only use in-memory objects (user could send anything!)
	var walletObj=requestData.wallet;
	var wallet=getWalletById(walletObj._id); //only use in-memory objects (user could send anything!)	
	var account=requestData.account;	
	var claimAmount=requestData.claimAmount;	
	var errString="";
	if (wallet==null) {
		errString="wallet "+wallet._id+" does not exist";
		error(errString);
		responseData.data.error=errString;
		responseData.data.errNum=2;
		response.end(JSON.stringify(responseData));
		return;
	}
	if (faucet==null) {
		errString="faucet "+faucet._id+" does not exist";
		error(errString);
		responseData.data.error=errString;
		responseData.data.errNum=2;
		response.end(JSON.stringify(responseData));
		return;
	}
	if (faucetReady(wallet,faucet)==false) {
		errString="wallet "+wallet._id+" has already been claimed for faucet "+faucet._id;
		error(errString);
		responseData.data.error=errString;
		responseData.data.errNum=2;
		response.end(JSON.stringify(responseData));
		return;
	}
	console.log(color().yellow+"      Updating wallet: "+color().green+wallet._id+" ["+wallet.address+"]");
	console.log(color().yellow+"      Querying faucet: "+color().green+faucet._id);
	var validateURL=faucetObj.validateURL;	
	validateURL=validateURL.split("%address%").join(wallet.address);
	var data=yield loadURL(validateURL, generator);	
	try {			
		var amount=eval(faucet.validateParseScript); 
	} catch (err) {
		var amount=-1;
	}	
	if ((wallet.balance==undefined) || (wallet.balance==null)) {
		wallet.balance=0;
	}
	//JavaScript does strange things to numbers sometimes...
	wallet.balance=Math.round(wallet.balance);
	var newBalance=Math.round(wallet.balance+claimAmount);	
	console.log(color().yellow+"   New wallet balance: "+color().green+newBalance);	
	result=yield database.find("accounts",{account:requestData.account}, generator);
	if (result[0]==undefined) { 
		//account doesn't exist so create it
		var insertObj=new Object();
		insertObj.account=account;
		insertObj.games=new Object();
		insertObj.games[responseData.gameID]=new Object();		
		insertObj.games[responseData.gameID].balance=0;
		insertObj.games[responseData.gameID].shares=0;
		insertObj.games[responseData.gameID].thresholdSpins=0;
		insertObj.games[responseData.gameID].units="gwei"; //this should come from the client
		var result=yield database.insert("accounts", insertObj, generator);		
	}	
	wallet.balance=amount;		
	setWalletFaucetTime(wallet, faucet);
	storeWallet(wallet);
	if (newBalance<=amount) {	
		result=yield database.find("accounts",{account:account}, generator);		
		console.log(color().yellow+"              Game ID: "+color().green+responseData.gameID);
		console.log(color().yellow+"    Crediting account: "+color().green+account);							
		result[0].games[responseData.gameID].balance+=claimAmount;
		console.log(color().yellow+"  New account balance: "+color().green+result[0].games[responseData.gameID].balance+color().reset);			
		database.update("accounts",{account:account},{games:result[0].games});		
		responseData.data.balance=result[0].games[responseData.gameID].balance;		
		responseData.data.shares=result[0].games[responseData.gameID].shares;		
		responseData.data.thresholdSpins=result[0].games[responseData.gameID].thresholdSpins;
		var thresholdPercent=(result[0].games[responseData.gameID].thresholdSpins/requiredThresholdSpins)*100;
		if (thresholdPercent>100) {
			thresholdPercent=100;
		}
		responseData.data.thresholdPercent=thresholdPercent;
		response.end(JSON.stringify(responseData));
		if (newBalance<amount) {
			console.log(color().red+"   Remote wallet balance exceeds local balance (probably updated externally).");
		}
	} else {
		//wallet might be out of sync
		console.log(color().red+"    Claim can't be verified for account: "+color().green+account+color().reset);
		//set balance and disable wallet for time limit		
	}
}

function loadURL(URL, generator) {		
	var requestObj=new Object();
	requestObj.uri=URL;
	requestObj.method="GET";
	requestObj.jar=true; //use cookies!
	request(requestObj, function (error, response, body) {
		if (!error && response.statusCode == 200) {
			generator.next(body);
		}
	})
}

/**
* reelData: indexed array of reel lengths (# of symbols)
*    e.g. [12,14,24] (reel 0=12 symbols, reel 1=14 symbols, etc.)
* responseObject: HTTP reesponse object
*/
function* generateReelResults(requestData, responseData, response, gameDefinition) {
	var generator=yield;
	//var gameDefinition=getGameDefByID(requestData.gameID);
	if (gameDefinition.reels.length != requestData.reels.length) {
		error ("requested reel definition does not matching current one!");
		return;
	}
	responseData.data=new Object();
	var result=yield database.find("accounts", {account:requestData.account}, generator);
	if (result.length<0) {
		error("account does not exist");
		responseData.data.error="account does not exist";
		responseData.data.errNum=1;
		response.end(JSON.stringify(responseData));
		return;
	}
	if (result[0].balance<=0) {
		error("account balance is insufficient");
		responseData.data.balance=result[0].balance;
		responseData.data.error="insufficient account balance";
		responseData.data.errNum=1;
		response.end(JSON.stringify(responseData));
		return;		
	}
	console.log("   Requested game ID: "+responseData.gameID);
	console.log("   Generating result values for "+gameDefinition.reels.length+" reels");		
	responseData.data.reels=[];
	var sessionKey=generateXXTEAKey64();
	result[0].games[responseData.gameID].sessionKey=sessionKey;	
	result=yield database.update("accounts", {account:requestData.account}, {games:result[0].games}, generator);
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
	response.end(JSON.stringify(responseData));
}

function *processGameResults(requestData, responseData, response, gameDefinition) {
	var generator=yield;
	responseData.data=new Object();
	console.log("   Requested game ID: "+responseData.gameID);
	var result=yield database.find("accounts", {account:requestData.account}, generator);
	if (result.length<1) {
		error("account information could not be retrieved!");
		return;
	}	
	if ((result[0].games[responseData.gameID].sessionKey=="") || (result[0].games[responseData.gameID].sessionKey==null) || (result[0].games[responseData.gameID].sessionKey==undefined)) {
		error("sessionKey key for account doesn't not exist. Was game started?");
		return;
	}
	var sessionKey=result[0].games[responseData.gameID].sessionKey;
	var stopPositions=new Array();
	var fill="";
	for (var count=0; count<requestData.selections.length; count++) {
		var encSelection=requestData.selections[count];
		var stopPosHex=decryptStopPosition(encSelection, sessionKey);
		var stopPos=parseInt("0x"+stopPosHex);
		stopPositions.push(stopPos);
		if (stopPos<10) {
			fill=" ";
		} else {
			fill="";
		}
		console.log("   stop pos for reel "+count+": "+fill+stopPos+" ("+stopPosHex+") => "+getSymbolDefinition(gameDefinition, count, stopPos).name);
	}
	if ((requestData.wager==undefined) || (requestData.wager==null) || (requestData.wager==undefined)) {
		requestData.wager=1000; //default wager if unspecified
	}	
	result=yield database.find("accounts", {account:requestData.account}, generator);	
	if (result.length<1) {
		//account doesn't exist! what else should we do here?
		return;
	}	
	result[0].games[responseData.gameID].balance-=requestData.wager;
	//thresholdSpins -> number of non-winning spins (when min value reached, shareholder transaction is covered so start counting shares)
	//value must be reset in database when share is disbursed!
	if ((result[0].games[responseData.gameID].thresholdSpins==undefined) || (result[0].games[responseData.gameID].thresholdSpins==null)) {
		result[0].games[responseData.gameID].thresholdSpins=0;
	}
	if ((result[0].games[responseData.gameID].shares==undefined) || (result[0].games[responseData.gameID].shares==null)) {		
		result[0].games[responseData.gameID].shares=0;		
	}	
	var winObj=checkWin(stopPositions,gameDefinition);
	var winningStops=getWinningStops(winObj.symbols, stopPositions);
	var winAmount=requestData.wager*winObj.multiplier;			
	var remainingTreshSpins=(requiredThresholdSpins-result[0].games[responseData.gameID].thresholdSpins);
	if (remainingTreshSpins<0) {		
		remainingTreshSpins=0;
	}	
	if (winAmount==0) {
		//count only non-winning spins
		result[0].games[responseData.gameID].thresholdSpins++;
	}
	if ((activeGameShares[responseData.gameID]==null) || (activeGameShares[responseData.gameID]==undefined)) {
		activeGameShares[responseData.gameID]=0;
	}
	if ((totalGameShares[responseData.gameID]==null) || (totalGameShares[responseData.gameID]==undefined)) {
		totalGameShares[responseData.gameID]=0;
	}
	if (remainingTreshSpins==0) {
		//include in active shares count
		activeGameShares[responseData.gameID]+=winObj.shares;
	}
	//this should be dynamic -- calculate how many spins to cover transaction (currently minimum of 50)
	result[0].games[responseData.gameID].shares+=winObj.shares;
	totalGameShares[responseData.gameID]+=winObj.shares;
	result[0].games[responseData.gameID].balance+=winAmount;
	console.log(color().green+"                      Win: "+color().yellow+winObj.name);
	console.log(color().green+"                    Wager: "+color().yellow+requestData.wager);
	console.log(color().green+"               Multiplier: "+color().yellow+winObj.multiplier);
	console.log(color().green+"               Won amount: "+color().yellow+winAmount);
	console.log(color().green+"               Shares won: "+color().yellow+result[0].games[responseData.gameID].shares);
	console.log(color().green+"Threshold spins remaining: "+color().yellow+remainingTreshSpins);	
	console.log(color().green+"              New balance: "+color().yellow+result[0].games[responseData.gameID].balance+color().reset);
	console.log(" ");
	console.log(color().green+"       Total shares issued: "+color().yellow+totalGameShares[responseData.gameID]+color().reset);
	console.log(color().green+"      Active shares issued: "+color().yellow+activeGameShares[responseData.gameID]+color().reset);
	//compare winning combinations here to determine win amount, pay out as appropriate
	result[0].games[responseData.gameID].sessionKey=null;
	var updateResult=yield database.update("accounts", {account:requestData.account}, {games:result[0].games}, generator);
	responseData.data.win=winAmount;
	responseData.data.winningStops = winningStops;
	responseData.data.shares=result[0].games[responseData.gameID].shares;
	responseData.data.thresholdSpins=(result[0].games[responseData.gameID].thresholdSpins);	
	var thresholdPercent=(result[0].games[responseData.gameID].thresholdSpins/requiredThresholdSpins)*100;
	if (thresholdPercent>100) {
		thresholdPercent=100;
	}	
	responseData.data.thresholdPercent=thresholdPercent;
	responseData.data.balance=result[0].games[responseData.gameID].balance;
	responseData.data.key=sessionKey;
	if (winAmount>0) {		
		payWinnings(requestData, winAmount);
	}
	response.end(JSON.stringify(responseData));
}

function* getShareholderInfo(requestData, responseData, response, gameDefinition) {
	var generator=yield;
	responseData.data=new String();
	console.log("   Requested game ID: "+responseData.gameID);	
	var resultsFound=0;
	//stylesheet(s) can be preloaded per game 
	var stylesheet="body {color: #000000;background: #FFFFF0;font-family: \"Century Gothic\", \"Arial\", \"sans-serif\", \"_sans\";}";
	stylesheet+=".fieldname{font-weight: bold;color: #0A0A0A;}";
	stylesheet+=".fieldinfo{font-weight: bolder;color: #00AA00;}";
	var result=yield database.find("accounts", {account:requestData.account}, generator);
	responseData.data="<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">";
	responseData.data+="<title>Shareholder Information</title>";
	responseData.data+="<style>"+stylesheet+"</style>";
	responseData.data+="</head><body>";
	for (var gameID in result[0].games) {
		if (gameID == responseData.gameID) {
			resultsFound++;
			responseData.data+="<p><span class='fieldname'>Account:</span><span class='fieldinfo'> ";
			responseData.data+=requestData.account+"</span></p>";
			responseData.data+="<p><span class='fieldname'>Game:</span><span class='fieldinfo'> ";
			responseData.data+=gameDefinition.name+"</span></p>";
			responseData.data+="<p><span class='fieldname'>Current balance:</span><span class='fieldinfo'> ";
			responseData.data+=result[0].games[gameID].balance+" "+result[0].games[gameID].units+"</span></p>";
			responseData.data+="<p><span class='fieldname'>Spins / Shareholder Threshold:</span><span class='fieldinfo'> ";
			responseData.data+=result[0].games[gameID].thresholdSpins+" / "+requiredThresholdSpins+" ("+roundToTwo((result[0].games[gameID].thresholdSpins / requiredThresholdSpins) * 100)+"%)</span></p>";
			responseData.data+="<p><span class='fieldname'>Your shares / Total shares:</span><span class='fieldinfo'> ";
			responseData.data+=result[0].games[gameID].shares+" / "+totalGameShares[gameID]+" ("+roundToTwo((result[0].games[gameID].shares / totalGameShares[gameID])*100)+"%)</span></p>";
			responseData.data+="<p><span class='fieldname'>Your active shares / Global active shares:</span><span class='fieldinfo'> ";			
			if (result[0].games[gameID].thresholdSpins>=requiredThresholdSpins) {
				responseData.data+=result[0].games[gameID].shares+" / "+activeGameShares[gameID]+" ("+roundToTwo((result[0].games[gameID].shares / activeGameShares[gameID])*10000)+"%)</span></p>";
			} else {
				responseData.data+="0 / "+activeGameShares[gameID]+" (0%)</span></p>";
			}
			break;
		}
	}
	if (resultsFound<1) {
		responseData.data+="<p><span class='fieldinfo'>No shareholder information is available yet for account: "+requestData.account+"</span></p>";
	}
	responseData.data+="</body></html>";
	response.end(JSON.stringify(responseData));
}	

/**
* Returns a multidimensional array of winning stop positions based on supplied winning symbols and winning stop positions.
* The returned array is structured as: [[#],[#],[#]] where each sub-array contains the winning symbol(s) for the associated reel (containing array).
* For example, [[0],[4],[6]] indicates that stop position 0 won on reel 0, stop position won on reel 4, and stop position 6 won on reel 2.
* In the following example, only stop position 23 won on reel 1: [[],[23],[]]
* This structure supports future expansion so that more than one stop position may be considered a win per reel for multiple paylines. For example:
* [[3,4],[5],[16,17,18]] (stops 3 and 4 won on reel 0, stop 5 won on reel 1, and stops 16,17,18 won on reel 2).
*/
function getWinningStops(winningSymbols, stopPositions) {
	var returnArr=[];
	if ((winningSymbols==null) || (winningSymbols==undefined)) {
		return (returnArr);
	}
	if (winningSymbols.length==0) {
		return (returnArr);
	}
	for (var count=0; count<stopPositions.length; count++) {
		returnArr.push([]);
		if (winningSymbols[count]>-1) {
			returnArr[count].push(stopPositions[count]);
		}
	}
	return (returnArr);
}


function payWinnings(requestData, amount) {
	var dateObj=new Date();
	database.insert("wins", {account:requestData.account, amount:amount, type:"ether", units:"gwei", date:dateObj.toISOString()});
	console.log ("   Paying "+amount+" to "+requestData.account);	
	var weiAmount=web3.toWei(amount, "gwei");
	console.log ("   value in wei: "+weiAmount);
	//the following is static -- change for actual payout values!
	web3.eth.sendTransaction({from:payoutWallet, to:requestData.account, value:"1500000000000000"});
}


function *getAccountBalance(requestData, responseData, response) {
	var generator=yield;
	responseData.data=new Object();			
	//var result=database.findAccount(requestData.account, onGetAccountBalance, {responseData:responseData, response:response});		
	var result=yield database.find("accounts", {account:requestData.account}, generator);		
	console.log(" Requested game ID: "+responseData.gameID);
	if (result.length>0) {		
		console.log("           Balance: "+result[0].games[responseData.gameID].balance+" "+result[0].games[responseData.gameID].units);		
		console.log("            Shares: "+result[0].games[responseData.gameID].shares);
		console.log("   Threshold Spins: "+result[0].games[responseData.gameID].thresholdSpins);
		responseData.data.units=result[0].games[responseData.gameID].units;
		responseData.data.balance=result[0].games[responseData.gameID].balance;
		responseData.data.thresholdSpins=result[0].games[responseData.gameID].thresholdSpins;
		var thresholdPercent=(result[0].thresholdSpins/requiredThresholdSpins)*100;
		if (thresholdPercent>100) {
			thresholdPercent=100;
		}
		responseData.data.thresholdPercent=thresholdPercent;
		responseData.data.shares=result[0].games[responseData.gameID].shares;
	} else {
		console.log("   Balance not found; returning 0");
		responseData.data.units="gwei";
		responseData.data.balance=0;
		responseData.data.thresholdSpins=0;
		responseData.data.thresholdPercent=0;
		responseData.data.shares=0;
	}
	response.end(JSON.stringify(responseData));
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
			if (winningSymbols[count] > -1) {				
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

function roundToTwo(num) {    
    return +(Math.round(num + "e+2")  + "e-2");
}

