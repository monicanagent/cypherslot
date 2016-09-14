/**
* 
* Main game logic and user interface controls.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{

	import HTTPComm;
	import crypto.RNG;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	import interfaces.ICommunication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.text.TextField;
	import ui.DialogManager;
	import FaucetWindow;
	import events.FaucetWindowEvent;
	import ui.Paytable;
	import HelpWindow;
	import HostInfoWindow;
	import org.xxtea.XXTEA;
	import org.xxtea.Base64;;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.utils.ByteArray;
	import ui.ColourSquare;
	import ui.LayoutController;
	import SoundController;
	import ui.Reel;	
	import ui.ResultsSelector;
	import flash.events.MouseEvent;
	import ui.ReelController;
	import events.ReelControllerEvent;
	import flash.net.SharedObject;	
	import flash.utils.setTimeout;
	import com.greensock.TweenLite;
	import com.greensock.easing.Strong;
	import flash.filters.ColorMatrixFilter;
	import AddressValidator;
	
	public class GameController 
	{
				
		public static const _gameInfo:Object = {name:"Faucet Slot", ID:1};
		private var _demoMode:Boolean = false; //local "demo" mode or live
		private var _config:XML;
		private var _reelController:ReelController;				
		private var _demoKey:String; //Base64-encoded
		private var _faucetWindow:FaucetWindow;
		private var _paytable:Paytable;
		private var _helpWindow:HelpWindow;
		private var _rng:RNG = new RNG(128);
		private var _comm:ICommunication;
		private var _balance:Number = 0;
		private var _shares:Number = 0;
		private var _wager:Number = 1000;
		private var _accountAddressOriginalY:Number = 0;
		private var _lastGameResults:Object = null;		
		
		public function GameController(config:XML) {
			this._config = config;			
			this._reelController = ReelController(LayoutController.element("reels"));
			this._reelController.addEventListener(ReelControllerEvent.REELS_STOPPED, this.onReelAnimationFinished);
			trace ("Reel configuration JSON:");
			trace (this._reelController.JSONdefinition);
			this._accountAddressOriginalY = LayoutController.element("payoutAddress").y;
			this.hidePayoutAddress();
			ResultsSelector.hideSelectors(0);
			LayoutController.element("soundToggle").addEventListener(MouseEvent.CLICK, this.onToggleSounds);
			if (this.soundsEnabled) {
				trace ("Enabling sounds");
				LayoutController.element("soundToggle").selected = true;
				SoundController.volume=1;
			} else {
				trace ("Disabling sounds");
				LayoutController.element("soundToggle").selected = false;
				SoundController.volume=0;
			}
			LayoutController.element("spinButton").addEventListener(MouseEvent.CLICK, this.onSpinClick);
			//LayoutController.element("submitButton").enabled = false;
			this.disableElement(LayoutController.element("spinButton"));
			LayoutController.element("submitButton").addEventListener(MouseEvent.CLICK, this.onSubmitClick);
			this.disableElement(LayoutController.element("submitButton"));
			LayoutController.element("submitButton").visible = false;
			LayoutController.element("payoutAddressToggle").addEventListener(MouseEvent.CLICK, this.showPayoutAddress);
			this.disableElement(LayoutController.element("addFunds"));
			LayoutController.element("addFunds").addEventListener(MouseEvent.CLICK, this.onAddFundsClick);
			LayoutController.element("helpButton").addEventListener(MouseEvent.CLICK, this.openHelp);
			LayoutController.element("payoutAddress").addEventListener(FocusEvent.FOCUS_OUT, this.onPayoutAddressLoseFocus);
			LayoutController.element("payoutAddress").border = true;
			LayoutController.element("payoutAddress").background = true;			
			LayoutController.element("payoutAddress").text = payoutAddress;
			LayoutController.element("payoutAddress").stage.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
			this._paytable = new Paytable(LayoutController.element("paytable"));
			this._paytable.hide(true);			
			LayoutController.element("shareholder_icon").content.addEventListener(MouseEvent.MOUSE_DOWN, this.getShareholderInfo);
			LayoutController.element("thresholdPercent").useHandCursor = true;
			LayoutController.element("thresholdPercent").buttonMode = true;
			LayoutController.element("thresholdPercent").addEventListener(MouseEvent.MOUSE_DOWN, this.getShareholderInfo);
			this.connectToHost();
		}
		
		private function displayPayoutAddressError(errString:String):void {
			var format:TextFormat = new TextFormat();
			format.color = 0xFFFFFF;			
			TextField(LayoutController.element("payoutAddress")).backgroundColor = 0xFF0000;
			TextField(LayoutController.element("payoutAddress")).addEventListener(Event.CHANGE, this.onPayoutAddressUpdate);			
			LayoutController.element("payoutAddress").text = errString;
			TextField(LayoutController.element("payoutAddress")).setTextFormat(format);
		}
		
		private function onPayoutAddressUpdate(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.CHANGE, this.onPayoutAddressUpdate);
			var format:TextFormat = new TextFormat();
			format.color = 0x000000;
			TextField(LayoutController.element("payoutAddress")).setTextFormat(format);
			TextField(LayoutController.element("payoutAddress")).backgroundColor = 0xFFFFFF;
		}
		
		private function get payoutAddress():String {
			var so:SharedObject = SharedObject.getLocal("cypherslot");
			if ((so.data["payoutAddress"] == null) || (so.data["payoutAddress"] == null)) {
				so.data.payoutAddress = "";
				so.flush();
			}
			return (so.data.payoutAddress);
		}		
		
		private function set payoutAddress(addrSet:String):void {
			trace ("Storing new payout address: " + addrSet);
			var so:SharedObject = SharedObject.getLocal("cypherslot");
			so.data.payoutAddress = addrSet;
			so.flush();
		}
		
		private function get soundsEnabled():Boolean {
			var so:SharedObject = SharedObject.getLocal("cypherslot");
			if ((so.data["soundsEnabled"] == null) || (so.data["soundsEnabled"] == null)) {
				so.data.soundsEnabled = true;
				so.flush();
			}
			return (so.data.soundsEnabled);
		}
		
		private function set soundsEnabled(enabledSet:Boolean):void {
			var so:SharedObject = SharedObject.getLocal("cypherslot");
			so.data.soundsEnabled = enabledSet;
			so.flush();			
		}
		
		private function onToggleSounds(eventObj:MouseEvent):void {	
			this.soundsEnabled = LayoutController.element("soundToggle").selected;
			if (this.soundsEnabled) {
				trace ("Enabling sounds");
				SoundController.volume=1;
			} else {
				trace ("Disabling sounds");
				SoundController.volume=0;
			}
		}
		
		private function onMouseDown(eventObj:MouseEvent):void {
			var addressObj:* = LayoutController.element("payoutAddress");
			var addressButton:* = LayoutController.element("payoutAddressToggle");
			if (!addressObj.hitTestPoint(eventObj.stageX, eventObj.stageY) && 
				!addressButton.hitTestPoint(eventObj.stageX, eventObj.stageY) &&
				(addressObj.y < addressObj.stage.stageHeight)) {
				trace ("Updating payout address");				
				this.updatePayoutAddress();
			}
		}
		
		private function updatePayoutAddress():void {
			var address:String = LayoutController.element("payoutAddress").text;
			if (AddressValidator.validateAddress(address) == null) {
				//support additional address types in the future
				this.disableElement(LayoutController.element("spinButton"));
				this.displayPayoutAddressError(address);
				this.showPayoutAddress(null);
				return;
			}			
			this.hidePayoutAddress();
			if (address != payoutAddress) {
				payoutAddress = address;
				this.disableElement(LayoutController.element("spinButton"));
				this.disableElement(LayoutController.element("addFunds"));
				this.requestAccountBalance(this.payoutAddress);
			} else {
				this.enableElement(LayoutController.element("spinButton"));
				this.enableElement(LayoutController.element("addFunds"));
				this.enableElement(LayoutController.element("payoutAddressToggle"));
			}
		}
		
		private function enableElement(uiElement:*):void {
			try {
				uiElement.enabled = true;
			} catch (err:*) {				
			}
			uiElement.filters = [];
		}
		
		private function disableElement(uiElement:*):void {
			try {
				uiElement.enabled = false;
			} catch (err:*) {				
			}
			var rLum : Number = 0.2225;
			var gLum : Number = 0.7169;
			var bLum : Number = 0.0606; 
			var matrix:Array = [ rLum, gLum, bLum, 0, 0,
								rLum, gLum, bLum, 0, 0,
								rLum, gLum, bLum, 0, 0,
								0,    0,    0,    1, 0 ]; 
			var filter:ColorMatrixFilter = new ColorMatrixFilter( matrix );
			uiElement.filters = [filter];
		}		
		
		private function connectToHost():void {				
			//var hostURL:String = this._config.network.host.toString();
			var hostURL:String = this._config.network.anonhost.toString();
			var proxy:String = this._config.network.anonproxy.toString();
			var proxyIP:String = proxy.split(":")[0];
			var proxyPort:uint = uint(proxy.split(":")[1]);
			if (!_demoMode){ 
				trace ("GameController.connectToHost: " + hostURL);
				trace ("Using Tor proxy: " + proxy);
				//this._comm = new HTTPComm(hostURL);
				this._comm = new TorComm(hostURL, proxyIP, proxyPort);
				this._comm.gameInfo = _gameInfo;
				this._comm.connect(this.onConnectHost);
			}
		}
		
		private function onConnectHost():void {
			DialogManager.hide("info");
			this.requestAccountBalance(this.payoutAddress);
		}
		
		private function requestAccountBalance(accountAddress:String):void {
			this.disableElement(LayoutController.element("spinButton"));
			this.disableElement(LayoutController.element("addFunds"));
			this.disableElement(LayoutController.element("payoutAddressToggle"));			
			if ((this.payoutAddress == null) || (this.payoutAddress == "")) {
				this.displayPayoutAddressError("Enter Ethereum wallet address for winning payouts");
				this.showPayoutAddress(null);
			} else {
				trace ("Requesting balance for account " + accountAddress);
				this._comm.request("balance", {account:accountAddress}, this.onReceiveAccountBalance);
			}	
		}
		
		private function getShareholderInfo(eventObj:MouseEvent):void {
			/*
			var hostURL:String = this._config.network.anonhost.toString();
			var proxy:String = this._config.network.anonproxy.toString();
			var proxyIP:String = proxy.split(":")[0];
			var proxyPort:uint = uint(proxy.split(":")[1]);
			var comm:TorComm = new TorComm(hostURL, proxyIP, proxyPort);
			comm.request("shareholderinfo", {account:this.payoutAddress}, this.onReceiveShareholderInfo);
			*/
			this._comm.request("shareholderinfo", {account:this.payoutAddress}, this.onReceiveShareholderInfo);
		}
		
		private function onReceiveShareholderInfo(eventObj:Event):void {
			trace ("onReceiveShareholderInfo=" + eventObj.target.data);
			var htmlContent:String = JSON.parse(eventObj.target.data).data;
			var options:NativeWindowInitOptions = new NativeWindowInitOptions(); 
			options.transparent = false; 
			options.systemChrome = NativeWindowSystemChrome.STANDARD; 
			options.type = NativeWindowType.NORMAL; 			
			//if already open, existing window will get focus
			var helpWindow:HostInfoWindow = new HostInfoWindow(options, htmlContent, 600, 300);	
		}
		
		private function onReceiveAccountBalance(eventObj:Event):void {						
			eventObj.target.removeEventListener(Event.COMPLETE, this.onReceiveAccountBalance);			
			var responseData:Object = JSON.parse(eventObj.target.data).data;
			trace ("onReceiveAccountBalance=" + eventObj.target.data);
			this._balance = responseData.balance;
			this._shares = responseData.shares;
			LayoutController.element("balance").text = String(this._balance);
			LayoutController.element("shares").text = String(this._shares);
			LayoutController.element("thresholdPercent").percent = responseData.thresholdPercent;
			this.enableElement(LayoutController.element("spinButton"));
			this.enableElement(LayoutController.element("addFunds"));
			this.enableElement(LayoutController.element("payoutAddressToggle"));
		}
		
		private function requestReelResults():void {
			this._paytable.hide();
			if (_demoMode) {
				this.generateResults();
			} else {	
				//server will return error if the number of icons don't match server settings
				var reelSizes:Array = [this._reelController.reels[0].icons.length, this._reelController.reels[1].icons.length, this._reelController.reels[2].icons.length];
				this._comm.request("genreelres", {reels:reelSizes, account:this.payoutAddress}, this.onReceiveReelResults);
			}
		}
		
		private function onPayoutAddressLoseFocus(eventObj:FocusEvent):void {
			this.updatePayoutAddress();
			//this.hidePayoutAddress();
		}
		
		private function onReceiveReelResults(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, this.onReceiveReelResults);
			var resultObject:Object = JSON.parse(eventObj.target.data).data;
			if ((resultObject.error==undefined) || (resultObject.errNum==0)) {
				processReelResults(resultObject);
			} else {
				trace ("Server response error: " + resultObject.error);
			}
		}
		
		private function submitSelectedResults(results:Array):void {
			if (_demoMode) {
				this.sendKey();
			} else {
				this._paytable.show();
				this._comm.request("select", {selections:results, account:this.payoutAddress}, this.onReceiveGameResults);
			}
		}
		
		private function toHex(input:uint):String {					
			var digits:String = "0123456789ABCDEF";
			var hex:String = new String("");
			while (input > 0) {				
				var charIndex:uint = input & 0xF;
				input = input >>> 4;
				hex = digits.charAt(charIndex) + hex; 
			}
			if (hex.length == 0) {
				hex = '0';
			}			
			return (hex); 
		}
		
		private function generateResults():void {			
			var key:ByteArray = new ByteArray();
			var keyArr:Array = new Array();
			for (var count:uint = 0; count < 4; count++) {
				var rand:uint = _rng.getRandomUint();				
				key.writeUnsignedInt(rand);				
			}
			var resultsObj:Object = new Object();
			resultsObj.reels = new Array();
			var resultStrings:Vector.<String> = new Vector.<String>();
			this._demoKey = Base64.encode(key);			
			for (var reelCount:uint = 0; reelCount < 3; reelCount++) {
				resultsObj.reels[reelCount] = new Array();
				var currentReelData:XML = this.getReelConfig(reelCount);
				trace ("Encrypting " + currentReelData.children().length() + " stop positions for reel " + reelCount);
				for (count = 0; count < currentReelData.children().length(); count++) {										
					//blocks are 64 bits
					var block:String = new String()
					block = toHex(_rng.getRandomUint()); //32 random bits
					var stopVal:uint = (_rng.getRandomUint() << 16) | count; //16 random bits + stop position
					block += toHex (stopVal);										
					var encStop:String=Base64.encode(XXTEA.encrypt(block, key));
					resultStrings.push(encStop);					
				}
				resultStrings = shuffle(resultStrings);
				resultsObj.reels[reelCount] = this.vectorToArray(resultStrings);
				resultStrings = new Vector.<String>();				
			}
			trace (JSON.stringify(resultsObj));			
			processReelResults(resultsObj);
		}
		
		private function vectorToArray(input:Vector.<String>):Array {
			var output:Array = new Array();			
			for (var count:uint = 0; count < input.length; count++) {
				output.push(input[count]);
			}
			return (output);
		}
		
		private function sendKey():void {
			var gameObj:Object = new Object();
			gameObj.win = 0;
			gameObj.key = this._demoKey;
			this.processGameResults(gameObj);
		}
		
		private function appendResults(targetNode:XML, results:Vector.<String>):void {
			for (var count:uint = 0; count < results.length; count++) {				
				targetNode.appendChild(new XML("<result>" + results[count] + "</result>"));
			}
		}
		
		private function shuffle(input:Vector.<String>):Vector.<String> {
			var returnVec:Vector.<String> = new Vector.<String>();
			while (input.length > 0) {				
				var splicePos:int = Math.floor((_rng.getRandomInt() / int.MAX_VALUE) * input.length);
				returnVec.push(input.splice(splicePos, 1));
			}
			return (returnVec);
		}
		
		private function getReelConfig(reelID:uint):XML {
			var reelNodes:XMLList = _config.reels.children();
			for (var count:uint = 0; count < reelNodes.length(); count++) {
				if (uint(reelNodes[count].@id) == reelID) {
					return (reelNodes[count] as XML);
				}
			}
			return (null);
		}
		
		private function processReelResults(resultsData:Object):void {
			var reelsArray:Array = resultsData.reels;
			for (var count:uint = 0; count < reelsArray.length; count++) {
				var currentReel:Array = reelsArray[count];				
				for (var count2:uint = 0; count2 < currentReel.length; count2++) {					
					var encodedValue:String = currentReel[count2];
					var renderValue:String = Base64.decodeToHex(encodedValue);				
					ResultsSelector.getSelectorByID(count).addResultItem(new ColourSquare(renderValue, encodedValue));
				}
			}
			if (LayoutController.element("autoselect").selected) {
				this.autoSelectResults();
			} else {
				ResultsSelector.showSelectors(0.5, 0.3);
				LayoutController.element("spinButton").visible = false;
				this.disableElement(LayoutController.element("submitButton"));				
				LayoutController.element("submitButton").visible = true;
				this.enableElement(LayoutController.element("submitButton"));
			}
		}
		
		private function autoSelectResults():void {
			for (var count:uint = 0; count < 3; count++) {				
				 ResultsSelector.getSelectorByID(count).autoSelect();
			}
			var selections:Array = new Array();
			for (count = 0; count < 3; count++) {
				selections.push(ResultsSelector.getSelectorByID(count).currentSelection);
			}
			this._balance-= this._wager;
			LayoutController.element("balance").text = String(this._balance);
			setTimeout(submitSelectedResults, 1500, selections);
		}
		
		private function onReceiveGameResults(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, this.onReceiveGameResults);
			trace ("onReceiveGameResults: " + eventObj.target.data);
			var resultObject:Object = JSON.parse(eventObj.target.data).data;			
			this.processGameResults(resultObject);
		}
		
		private function processGameResults(resultsObj:Object):void {
			var winAmountStr:String = resultsObj.win;
			var keyStr:String = resultsObj.key;
			this._balance = resultsObj.balance;
			this._shares = resultsObj.shares;
			this._lastGameResults = resultsObj;
			//process after animation has completed
			//LayoutController.element("balance").text = String(this._balance);
			//LayoutController.element("shares").text = String(this._shares);
			LayoutController.element("thresholdPercent").percent = resultsObj.thresholdPercent;
			var key:ByteArray = Base64.decode(keyStr);
			trace ("Received encryption key: " + keyStr);
			var stopPositions:Array = new Array();
			for (var count:uint = 0; count < 3; count++) {
				var reelSelection:String = ResultsSelector.getSelectorByID(count).currentSelection;
				var plaintextSelection:String = XXTEA.decryptToString(reelSelection, key);
				var stopPosition:int = uint("0x" + plaintextSelection.substring(plaintextSelection.length - 4)); //last 4 digits of string (16 bits)
				stopPosition--; //stop position is for icon on payline
				if (stopPosition < 0) {
					stopPosition = _reelController.reels[count].icons.length - 1;
				}
				stopPositions.push(uint(stopPosition));
			}
			_reelController.stopAllReels(stopPositions, false, 1500);						
		}
		
		private function onReelAnimationFinished(eventObj:ReelControllerEvent):void {			
			if (this._lastGameResults.winningStops.length > 0) {
				if (this._lastGameResults.win > 0) {
					SoundController.playSound("bigWin", 0.3);
				} else {
					SoundController.playSound("win", 0.3);
				}
			}
			ResultsSelector.clearAllSelectors();
			this.animateWinningIcons(this._lastGameResults.winningStops);
			this.enableElement(LayoutController.element("addFunds"));
			this.enableElement(LayoutController.element("payoutAddressToggle"));
			LayoutController.element("balance").text = String(this._balance);
			LayoutController.element("shares").text = String(this._shares);
			LayoutController.element("spinButton").visible = true;
			this.enableElement(LayoutController.element("spinButton"));
			LayoutController.element("submitButton").visible = false;
			this.disableElement(LayoutController.element("submitButton"));			
		}
		
		private function animateWinningIcons(stopPositions:Array):void {
			for (var count:int = 0; count < stopPositions.length; count++) {
				var currentReel:Reel = this._reelController.reels[count];
				for (var iconCount:int = 0; iconCount < stopPositions[count].length; iconCount++) {
					currentReel.icons[stopPositions[count][iconCount]].animateWin();
				}
			}
		}
		
		private function onSpinClick(eventObj:MouseEvent):void {
			if (LayoutController.element("spinButton").enabled == false) {
				return;
			}
			this._reelController.clearAllWinAnimations();
			if (this._balance < 1000) {				
				this.getFaucetData();
				return;
			}
			if (!_reelController.reelsSpinning) {
				this.disableElement(LayoutController.element("payoutAddressToggle"));
				this.disableElement(LayoutController.element("spinButton"));
				this.disableElement(LayoutController.element("addFunds"));				
				if (!LayoutController.element("autoselect").selected) {
					LayoutController.element("submitButton").visible = true;
					LayoutController.element("spinButton").visible = false;					
				}
				_reelController.spinAllReels(true, 0.3, 100);
				this.requestReelResults();
			}
		}
		
		private function onSubmitClick(eventObj:MouseEvent):void {
			if (LayoutController.element("submitButton").enabled == false) {
				return;
			}
			var selections:Array = new Array();
			for (var count:uint = 0; count < 3; count++) {
				var currentSelector:ResultsSelector = ResultsSelector.getSelectorByID(count);
				if (currentSelector.currentSelection!=null) {
					selections.push(currentSelector.currentSelection);
				}
			}
			if (selections.length == 3) {
				//LayoutController.element("submitButton").enabled = false;
				this.disableElement(LayoutController.element("submitButton"));
				this._balance-= this._wager;
				LayoutController.element("balance").text = String(this._balance);
				ResultsSelector.hideSelectors(0.5, 0);
				submitSelectedResults(selections);
			} else {
				//play some animation here
				trace ("Not all results selected!");
			}
		}
		
		private function onAddFundsClick(eventObj:MouseEvent):void {
			if (LayoutController.element("addFunds").enabled!=false) {
				this.getFaucetData();
			}
		}	
		
		private function getFaucetData():void {
			this.disableElement(LayoutController.element("spinButton"));
			this.disableElement(LayoutController.element("addFunds"));
			this.disableElement(LayoutController.element("payoutAddressToggle"));
			if (this._faucetWindow==null) {
				this._comm.request("getfaucet", {account:this.payoutAddress}, this.onGetFaucetData);
			} else {
				this._faucetWindow.activate();
			}
		}
		
		private function onGetFaucetData(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, this.onGetFaucetData);
			var wfData:Object = JSON.parse(eventObj.target.data).data; //wallet/faucet data			
			if (wfData!=null) {
				this.openFaucetWindow(wfData);
			} else {
				this.enableElement(LayoutController.element("spinButton"));
				this.enableElement(LayoutController.element("addFunds"));
				this.enableElement(LayoutController.element("payoutAddressToggle"));
				//no faucets currently available!
			}
		}
		
		public function openFaucetWindow(wfData:Object) :void {	
			var options:NativeWindowInitOptions = new NativeWindowInitOptions(); 
			options.transparent = false; 
			options.systemChrome = NativeWindowSystemChrome.STANDARD; 
			options.type = NativeWindowType.NORMAL; 
			_faucetWindow = new FaucetWindow(options, "Add credits to account "+this.payoutAddress, 800, 600);
			_faucetWindow.addEventListener(FaucetWindowEvent.COMPLETE, this.onFaucetClaimComplete);
			_faucetWindow.addEventListener(FaucetWindowEvent.CLOSING, this.onFaucetWindowClosing);
			_faucetWindow.load(wfData);
		}
		
		private function onFaucetClaimComplete(eventObj:FaucetWindowEvent):void {
			eventObj.target.addEventListener(FaucetWindowEvent.COMPLETE, this.onFaucetClaimComplete);
			var requestObj:Object = new Object();
			requestObj.faucet = eventObj.wfData.faucet;
			requestObj.wallet = eventObj.wfData.wallet;
			requestObj.account = this.payoutAddress;
			requestObj.claimAmount = eventObj.claimAmount;
			this._comm.request("claim", requestObj, this.onFaucetClaimVerified);
			trace ("New faucet amount claimed: " + eventObj.claimAmount);			
		}
		
		private function onFaucetClaimVerified(eventObj:Event):void {	
			trace ("onFauceClaimVerified: " + eventObj.target.data);
			eventObj.target.removeEventListener(Event.COMPLETE, this.onFaucetClaimVerified);		
			var replyObj:Object = JSON.parse(eventObj.target.data).data;
			if (isNaN(replyObj.balance) || isNaN(replyObj.shares)) {
				//claim couln't be verified
				var claimMsg:String = "<font color='#00FF10' size='24'><br><br><br><br><b>The faucet claim couldn't be verified. Please try again.</b></font>";
				DialogManager.show("info", claimMsg);
				LayoutController.layoutTarget.stage.addEventListener(MouseEvent.CLICK, this.hideInfoDialog);
			} else {
				this._balance = replyObj.balance;
				this._shares = replyObj.shares;
				this._faucetWindow = null;
				LayoutController.element("balance").text = String(this._balance);
				LayoutController.element("shares").text = String(this._shares);
				LayoutController.element("thresholdPercent").percent = replyObj.thresholdPercent;
			}
		}
		
		private function hideInfoDialog(eventObj:MouseEvent):void {
			DialogManager.hide("info");
				LayoutController.layoutTarget.stage.addEventListener(MouseEvent.CLICK, this.hideInfoDialog);
		}
		
		private function onFaucetWindowClosing(eventObj:FaucetWindowEvent):void {
			this.enableElement(LayoutController.element("spinButton"));
			this.enableElement(LayoutController.element("addFunds"));
			this.enableElement(LayoutController.element("payoutAddressToggle"));
			eventObj.target.removeEventListener(FaucetWindowEvent.CLOSING, this.onFaucetWindowClosing);					
			this._faucetWindow = null;
		}
		
		private function showPayoutAddress(eventObj:MouseEvent):void {
			var addressObj:*=LayoutController.element("payoutAddress"); //may be any type of display object
			TweenLite.killTweensOf(addressObj);
			this.disableElement(LayoutController.element("spinButton"));
			this.disableElement(LayoutController.element("addFunds"));
			this.disableElement(LayoutController.element("payoutAddressToggle"));
			if (addressObj.y != this._accountAddressOriginalY) {
				TweenLite.to(addressObj, 1, {y:this._accountAddressOriginalY, alpha:1, ease:Strong.easeOut});
			}			
		}
		
		private function hidePayoutAddress():void {
			var addressObj:*=LayoutController.element("payoutAddress"); //may be any type of display object
			TweenLite.killTweensOf(addressObj);
			if (addressObj.y != addressObj.stage.stageHeight) {
				TweenLite.to(addressObj, 1, {y:addressObj.stage.stageHeight, alpha:0, ease:Strong.easeOut});
			}
		}
		
		private function openHelp(eventObj:MouseEvent):void {
			trace ("openHelp: " + this._config.help.toString());
			var options:NativeWindowInitOptions = new NativeWindowInitOptions(); 
			options.transparent = false; 
			options.systemChrome = NativeWindowSystemChrome.STANDARD; 
			options.type = NativeWindowType.NORMAL; 			
			//if already open, existing window will get focus
			var helpWindow:HelpWindow = new HelpWindow(options, this._config.help.toString(), 600, 700);			
		}
		
		public function destroy():void {
			this._comm.disconnect();
			this._comm = null;
		}
		
	}

}