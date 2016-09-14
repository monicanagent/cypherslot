/**
* 
* Tor communication library and native client (Tor.exe) manager.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{
	import ui.ProgressBar;
	import flash.filesystem.File;
	import interfaces.ICommunication;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;	
	import org.torproject.SOCKS5Tunnel;
	import org.torproject.events.SOCKS5TunnelEvent;
	import org.torproject.model.HTTPResponseHeader;
	import org.torproject.model.HTTPCookie;
	import flash.net.URLRequest;	
	import events.CommunicationEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.events.Event;
	import events.TorCommEvent;
	import ui.DialogManager;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.events.ProgressEvent;
	import flash.utils.IDataInput;
	import flash.utils.ByteArray;
	
	public class TorComm extends EventDispatcher implements ICommunication 
	{		
		
		public static var _torProcess:NativeProcess = null; //the native Tor process launched by this instance
		private var _hostURL:String = null; //URL requested by this instance
		private var _proxyIP:String; //IP/address of the SOCKS5 (Tor) proxy
		private var _proxyPort:uint; //port of the SOCKS5 (Tor) proxy
		private var _timeoutID:uint = 0; //ID of timer used for communication timeouts
		private var _defaultGameObject:Object = null; //default game information object (setter/getter below)
		private static var _msgIDCounter:Number = 0; //unique request/response message counter
		private var _onConnect:Function = null;	//callback function invoked when connection to Tor network has been established
		private var _connectTimeout:Number; //time, in milliseconds, to wait for a connection to the Tor network
		private var _connectTimeoutProgress:Number; //current timeout counter used during connection to Tor network
		private var _requestQueue:Vector.<Object> = new Vector.<Object>(); //queue of requests to send to target URL
		private var _timeouts:Array = new Array(); //array of individual request timeouts
		private var _timeBar:ProgressBar; //Tor network connection progress bar
		
		public function TorComm(hostURL:String, socks5ProxyIP:String = "127.0.0.1", socks5proxyPort:uint = 9050) 
		{
			this._hostURL = hostURL;
			this._proxyIP = socks5ProxyIP;
			this._proxyPort = socks5proxyPort;			
		}
		
		private function runTorProcess():void {
			if (NativeProcess.isSupported == false) {
				trace ("NativeProcess is not supported in this runtime profile");
				return;
			}			
			this._timeBar = new ProgressBar();
			DialogManager.show("info", "<font color='#00FF10' size='24'><br><br><br><br><b>  Connecting to Tor network...</b></font>", [this._timeBar]);
			this._timeBar.x = 400;
			this._timeBar.y = 440;
			this._timeBar.width = 300;
			this._timeBar.height = 20;
			this._timeBar.percent = 0;
			var torConfig:String = "SocksPort " + String(this._proxyPort) + "\n";
			torConfig += "SocksBindAddress " + String(this._proxyIP)+"\n";
			var processInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();						
			processInfo.executable = File.applicationDirectory.resolvePath("Tor_x86/tor.exe");
			processInfo.workingDirectory = File.applicationDirectory.resolvePath("Tor_x86/");
			var torrc:File = File.applicationStorageDirectory.resolvePath("Tor/torrc");
			trace ("Creating Tor configuration (torrc): "+torrc.nativePath);
			var stream:FileStream = new FileStream();
			stream.open(torrc, FileMode.WRITE);
			stream.writeMultiByte(torConfig, "iso-8895-1");
			stream.close();
			processInfo.arguments.push ("-f");
			processInfo.arguments.push (torrc.nativePath);			
			_torProcess = new NativeProcess();
			_torProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onTorConsoleOutput);
			_torProcess.start(processInfo);
		}
		
		private function onTorConsoleOutput(eventObj:ProgressEvent):void {
			var stdOut:IDataInput = _torProcess.standardOutput; 			
			var data:String = stdOut.readUTFBytes(_torProcess.standardOutput.bytesAvailable); 
			trace ("tor.exe => " + data);
			var percent:Number = 0;
			var percentStart:int = data.indexOf("[notice] Bootstrapped") + 22;		
			if (percentStart > 21) {
				var percentEnd:int = data.indexOf("%", percentStart);
				var percentStr:String = data.substring(percentStart, percentEnd);
				percent = Number(percentStr);
				this._timeBar.percent = percent;
			}
			if (percent == 100) {
				this.connect(this._onConnect, this._connectTimeout);
			}
		}
		
		/* INTERFACE interfaces.ICommunication */
		
		public function connect(onConnect:Function = null, timeout:Number=50000):void 
		{
			_onConnect = onConnect;
			_connectTimeout = timeout;
			if (_torProcess == null) {
				this.runTorProcess();
				return;
			}			
			this._timeBar = new ProgressBar();
			this._timeBar.barColour = 0xF00A0A;
			DialogManager.show("info", "<font color='#00FF10' size='24'><br><br><br><br><b>  Connecting to game host...</b></font>", [this._timeBar]);
			this._timeBar.x = 400;
			this._timeBar.y = 440;
			this._timeBar.width = 300;
			this._timeBar.height = 20;
			this._timeBar.percent = 100;
			this._connectTimeoutProgress = timeout;
			this.sendStatusRequest(timeout);			
			this._timeoutID = setTimeout(this.onTimeoutTick, 500);
		}
		
		public function onTimeoutTick():void {
			this._connectTimeoutProgress -= 500;
			var percent:Number = Math.round((this._connectTimeoutProgress / this._connectTimeout) * 100);
			this._timeBar.percent = percent;			
			if (this._connectTimeoutProgress <= 0) {
				this.onConnectTimeout();
			} else {
				this._timeoutID = setTimeout(this.onTimeoutTick, 1000);
			}
		}
		
		public function request(type:String, data:Object = null, onComplete:Function = null, timeout:Number=25000):void 
		{
			_msgIDCounter++;			
			var requestInstance:URLRequest = new URLRequest(this._hostURL);
			requestInstance.method = URLRequestMethod.POST;
			var requestObj:Object = new Object;
			requestObj.request = type;
			requestObj.msgID = _msgIDCounter;
			requestObj.gameID = this._defaultGameObject.ID; //make sure to append ID
			requestObj.data = data;				
			requestInstance.data = JSON.stringify(requestObj);
			trace ("Sending request: " + requestInstance.data);
			var requestQueueObj:Object = new Object();			
			requestQueueObj.request = requestInstance;			
			requestQueueObj.onComplete = onComplete;			
			this._requestQueue.push(requestQueueObj);
			var tunnel:SOCKS5Tunnel = new SOCKS5Tunnel(this._proxyIP, this._proxyPort);
			tunnel.addEventListener(SOCKS5TunnelEvent.ONHTTPRESPONSE, this.onTunnelResponse);
			tunnel.addEventListener(SOCKS5TunnelEvent.ONTIMEOUT, this.onRequestTimeout);
			tunnel.addEventListener(SOCKS5TunnelEvent.ONCONNECTERROR, this.onProxyConnectError);
			trace ("Loading with timeout: "+timeout)
			tunnel.loadHTTP(requestInstance, timeout);			
		}
		
		public function onRequestTimeout(eventObj:SOCKS5TunnelEvent):void {
			trace ("onRequestTimeout: "+eventObj.request.data);			
			var parsedRequest:Object = JSON.parse(String(eventObj.request.data));			
			var errMsg:String = "<font size='24' color='#FF0000'><br><b>Request timed out!</b><br><br></font><font size='18' color='#FFFFFF'>Request #"+parsedRequest.msgID+" (\""+parsedRequest.request+"\") has timed out.</font>";
			errMsg += "<br><br><font color='#FFFFFF'>The host may be unavailable or the network may be congested.</font>";
			errMsg += "<br><br><font color='#FFFFFF'>Close the game and try again later.</font>";
			DialogManager.show("warning", errMsg);
		}
		
		private function getTimerIDByRequest(requestObj:URLRequest):uint {
			for (var count:uint = 0; count < _timeouts.length; count++) {
				if (_timeouts[count] == requestObj) {
					_timeouts.splice(count, 1);
					return (count);
				}
			}
			return (0);
		}
		
		private function onTunnelResponse(eventObj:SOCKS5TunnelEvent):void {
			trace ("onTunnelResponse");
			eventObj.target.removeEventListener(SOCKS5TunnelEvent.ONHTTPRESPONSE, this.onTunnelResponse);
			eventObj.target.removeEventListener(SOCKS5TunnelEvent.ONCONNECTERROR, this.onProxyConnectError);
			eventObj.target.addEventListener(SOCKS5TunnelEvent.ONTIMEOUT, this.onRequestTimeout);		
			var responseObj:Object = JSON.parse(eventObj.httpResponse.body);
			trace ("Response ID: " + responseObj.msgID);
			for (var count:int = 0; count < this._requestQueue.length; count++) {				
				if (eventObj.request == this._requestQueue[count].request) {
					var event:TorCommEvent = new TorCommEvent(Event.COMPLETE); //use a custom event here					
					event.target.data = eventObj.httpResponse.body;
					var queueObj:Object = this._requestQueue.splice(count, 1)[0];					
					if (queueObj.onComplete!=null) {
						queueObj.onComplete(event);
					}
					return;
				}
			}			
		}
		
		public function disconnect():void 
		{
			trace ("Closing Tor process...");
			_torProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onTorConsoleOutput);
			_torProcess.exit(true); //seems to need hard-kill to properly exit :(
			_torProcess = null;			
		}
		
		public function set gameInfo(infoSet:Object):void {
			this._defaultGameObject = infoSet;
		}
		
		public function get gameInfo():Object {
			return (this._defaultGameObject);
		}
		
		private function onProxyConnectError(eventObj:SOCKS5TunnelEvent):void {
			DialogManager.hide("info");
			eventObj.target.removeEventListener(SOCKS5TunnelEvent.ONHTTPRESPONSE, this.onTunnelResponse);
			eventObj.target.removeEventListener(SOCKS5TunnelEvent.ONCONNECTERROR, this.onProxyConnectError);
			clearTimeout(this._timeoutID);
			var errMsg:String = "<font size='24' color='#FF0000'><br><b>Tor proxy not found!</b><br><br></font><font size='18' color='#FFFFFF'>Tried SOCKS5 connection to </font><font size='20' color='#00A0FF'><b>" + this._proxyIP + ":" + this._proxyPort + "</b></font>";
			errMsg += "<br><br><font color='#FFFFFF'>You'll need to run the <a href='https://www.torproject.org/download/download.html.en'><u>Tor Bowser or Expert Bundle</u></a> before launching this game.</font>";
			errMsg += "<br><br><font color='#FFFFFF'>Update the &lt;<i>anonproxy</i>&gt; setting in the <a href='./config.xml'><u>config.xml</u></a> file if your proxy is using a non-default configuration.</font>";
			DialogManager.show("warning", errMsg);
		}
		
		public function onConnectTimeout():void {
			this._timeBar = null;
			DialogManager.hide("info");	
			var errMsg:String = "<br><font size='24' color='#FF0000'><b>Couldn't connect to game host!</b><br><br></font><font size='18' color='#FFFFFF'>Tor proxy is available but connection timed out while attempting to connect to the game host.</font>";
			errMsg += "<font size='18' color='#FFFFFF'><br><br>Host may be offline or temporarily unavailable.<br>Try again later.</font>";
			DialogManager.show("warning", errMsg);
		}
		
		private function sendStatusRequest(statusTimeout:Number):void {
			trace ("Requesting host status...");
			this.request("status", null, this.onStatusRequest, statusTimeout);			
		}
		
		private function onStatusRequest(eventObj:Event):void {
			clearTimeout(this._timeoutID);
			this._timeBar = null;
			trace ("Host status: " + eventObj.target.data);
			eventObj.target.removeEventListener(Event.COMPLETE, this.onStatusRequest);
			if (_onConnect != null) {
				_onConnect();
			}
			_onConnect = null;
		}
		
	}

}