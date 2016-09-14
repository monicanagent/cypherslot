package org.torproject  {
	
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;	
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;	
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import org.torproject.events.TorControlEvent;
	import org.torproject.model.TorControlModel;
	import org.torproject.model.TorASError;
	import flash.utils.setTimeout;
	
	/**
	 * Provides control and event handling services for core Tor services.
	 * 
	 * @author Patrick Bay
	 * 
	 * The MIT License (MIT)
	 * 
	 * Copyright (c) 2013 - 2016 Patrick Bay
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 * 
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE. 
	 */
	public class TorControl extends EventDispatcher {
		
		private static var torProcess:NativeProcess = null; //Native process running core Tor services		
		private var _launchServices:Boolean = true;
		private static const defaultControlIP:String = "127.0.0.1"; //Default control IP (usually 127.0.0.1)
		private static const defaultControlPort:int = 9051; //Default control port (usualy 9051)
		private static const defaultSOCKSIP:String = "127.0.0.1"; //Default SOCKS IP (usually 127.0.0.1)
		private static const defaultSOCKSPort:int = 1080; //Default SOCKS5 port (usually 1080)
		//Default assignments...
		private static var _controlIP:String = defaultControlIP; 
		private static var _controlPort:int = defaultControlPort;
		private static var _SOCKSIP:String = defaultSOCKSIP; 
		private static var _SOCKSPort:int = defaultSOCKSPort;		
		private static var _socket:Socket = null; //The actual control socket
		private static var _controlPasswordHash:String = null; //Control socket password hash
		private static var _controlPassword:String = null; //Control socket password (un-hashed)
		private var _connectDelay:Number = 1; //The delay, in seconds, to hold before attempting to connect to the control socket
		//Both of the following must be true before further commands can be issued:
		private static var _connected:Boolean = false; //Is control socket connected?
		private static var _authenticated:Boolean = false; //Has control socket authenticated?
		public static const rootTorPath:String = "./Tor_x86/"; //Relative path (to the output SWF / AIR file) to the Tor binary directory
		public static const executable:String = "tor.exe"; //Differs based on OS -- how best to dynamically control this?
		public static const configFile:String = "torrc"; //Standard config file name		
		/**
		 * The contents of the <config> node are parsed and used to generate the config file (specified above).
		 * Meta information may be included in the information. This includes:
		 * 
		 * %control_ip% - The control IP currently being used by the TorControl instance and running Tor services.
		 * %control_port% - The control port currently being used by the TorControl instance and running Tor services.
		 * %socks_ip% - The SOCKS IP currently being used by the running Tor proxy.
		 * %socks_port% - The SOCKS port currently being used by the running Tor proxy.
		 * %control_passhash% - The control pasword authentication hash.
		 */
		public static var configData:XML =<config><![CDATA[# TorAS Dynamic Configuration -- TorControl.configData
ControlPort %control_port%
ControlListenAddress %control_ip%
ClientOnly 1
SOCKSListenAddress %socks_ip%:%socks_port%
HashedControlPassword %control_passhash%
]]></config>
		private var _torPHProcess:NativeProcess = null; //Password hash process
		private var _synchResponseBuffer:String = new String(); //Used to buffer multi-line messages
		private var _asynchEventBuffer:String = new String(); //Used to buffer multi-line asynchronous messages
		private var _synchRawResponseBuffer:String = new String(); //Used to buffer multi-line messages in their raw state
		private var _asynchRawEventBuffer:String = new String(); //Used to buffer multi-line asynchronous messages in their raw state
		private var _enabledEvents:Array = new Array(); //Tracks which asynchronous Tor control events are enabled
		
		/**
		 * Creates an instance of TorControl.
		 * 
		 * @param	controlIP The control IP of the running Tor process. An empty or null string will cause the default value to be used.
		 * @param	controlPort The control port of the running Tor process. A negative value will cause the default value to be used.
		 * @param	SOCKSIP The SOCKS5 IP of the running Tor proxy. An empty or null string will cause the default value to be used.
		 * @param	SOCKSPort The SOCKS5 port of the running Tor proxy. A negative value will cause the default value to be used.
		 * @param	controlPass The control password (raw, or unhashed) required to access the Tor process control connection.
		 * @param	connectDelay Delay, in seconds, to wait to attempt to connect to the Tor control socket (allows Tor process to be started).
		 */
		public function TorControl(controlIP:String = defaultControlIP, controlPort:int = defaultControlPort, 
									SOCKSIP:String = defaultSOCKSIP, SOCKSPort:int=defaultSOCKSPort,
									controlPass:String = null, connectDelay:Number = 0) {
										
			if ((controlIP == null) || (controlIP == "")) {
				_controlIP = defaultControlIP
			} else {
				_controlIP = controlIP;
			}//else
			if (controlPort<0) {
				controlPort = defaultControlPort;
			} else {
				_controlPort = controlPort;
			}//else
			if ((SOCKSIP == null) || (SOCKSIP == "")) {
				_SOCKSIP = defaultSOCKSIP;
			} else {
				_SOCKSIP = SOCKSIP;
			}//else
			if (SOCKSPort<0) {
				_SOCKSPort = defaultSOCKSPort;
			} else {
				_SOCKSPort = SOCKSPort;
			}//else
			_controlPassword = controlPass;		
			this._connectDelay = connectDelay*1000;
		}//constructor
		
		/**
		 * The configuration data for the Tor services binary. This data is parsed (to replace any metatags),
		 * then written to the application data directory to be used by the Tor services binary at startup. If TorControl is
		 * not being used to launch the Tor binary, this data is ignored. Additionally, once the Tor binary has
		 * been started, this data will be ignored unless Tor is directed to reload it.
		 * 
		 * @param configSet The XML data to use for the Tor services binary. The format requires a single, top-level
		 * parent node (any name is acceptable), which contains a single CDATA section, which itself is the contents
		 * of the Tor binrary configration. See the TorControl <code>configData</code> property for an example, and
		 * refer to the Tor documentation for additional startup options.
		 */
		public function set config(configSet:XML):void {
			configData = configSet;
		}//set config
				
		public function get config():XML {
			return (configData);
		}//get config
		
		private function getPasswordHash(input:String):void {			
			if (this._torPHProcess != null) {
				this._torPHProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onHashPassword);
				this._torPHProcess = null;
			}//if			
			var launchInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var exeDirectory:File = File.applicationDirectory;
			var exeFile:File = File.applicationDirectory;				
			exeFile = exeFile.resolvePath(rootTorPath + executable);
			exeDirectory = exeDirectory.resolvePath(rootTorPath);								
			launchInfo.executable = exeFile;
			launchInfo.workingDirectory = exeDirectory;
			launchInfo.arguments.push("--hash-password");
			launchInfo.arguments.push(input);
			launchInfo.arguments.push("--quiet");
			this._torPHProcess = new NativeProcess();
			//Debug and log data are received over STDOUT
			this._torPHProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onHashPassword);
			this._torPHProcess.start(launchInfo);
		}//getPasswordHash
		
		private function onHashPassword(eventObj:ProgressEvent):void {
			_controlPasswordHash = this._torPHProcess.standardOutput.readMultiByte(this._torPHProcess.standardOutput.bytesAvailable, TorControlModel.charSetEncoding);			
			if (this._torPHProcess.running) {
				this._torPHProcess.exit(true);
			}//if
			this._torPHProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onHashPassword);
			this._torPHProcess = null;		
			this.launchTorProcess();
		}//onHashPassword
		
		/**
		 * Attempts to connect to the running Tor control process via pre-set (in constructor) socket settings.
		 */
		public function connect():void {
			this.prepareTorProcess();		
		}//connect
		
		/**
		 * Invoked when the Tor process is ready to accept a connection (for example, the process was successfully launched).
		 * 
		 * @param	... args Used internally to apply a startup delay. Set to true to bypass any startup delay (connect immediately).		 
		 */
		private function onTorControlReady(... args):void {			
			if (_socket == null) {
				if ((this._connectDelay > 0) && (args[0]!=true)){
					setTimeout(this.connect, this._connectDelay, true);					
					return;
				}//if	
				try {					
					_socket = new Socket(_controlIP, _controlPort);
					_socket.addEventListener(Event.CONNECT, this.onConnect);
					_socket.addEventListener(IOErrorEvent.IO_ERROR, this.onConnectError);
					_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConnectSecurityError);
					_socket.addEventListener(ProgressEvent.SOCKET_DATA, this.onData);						
				} catch (err:*) {
					trace ("TorControl.connect exception: "+err);
				}//catch
			} else {				
			}//else
		}//onTorControlReady
		
		/**
		 * Disconnects from the Tor control socket. Note that the Tor service may still be running at this point.
		 * 
		 * @param	shutdownService Also attempts to shut down the running Tor services process if true.
		 */
		public function disconnect(shutdownService:Boolean=true):void {
			if (shutdownService) {
				this.stopTorProcess();
			}//if				
			_socket.removeEventListener(Event.CONNECT, this.onConnect);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, this.onConnectError);
			_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConnectSecurityError);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, this.onData);
			_socket = null;
		}//disconnect
		
		/**
		 * Enables (true) or disables (false) the automatic launching of the Tor services binary at startup.
		 * If you are NOT planning to use the included Tor binary (i.e. you will launch it manually yourself), 
		 * make sure to set this value to false before calling <code>connect</code>.
		 */
		public function set launchServices(launchSet:Boolean):void {
			this._launchServices = launchSet;
		}//set launchServices
		
		public function get launchServices():Boolean {
			return (this._launchServices);
		}//get launchServices
		
		/**
		 * Prepares to launch the Tor process using supplied initialization data.
		 */
		public function prepareTorProcess():void {
			if (!this._launchServices) {
				this.onTorControlReady();
				return;
			}//if
			if (torProcess != null) {
				this.onTorControlReady();
				return;
			}//if
			if (NativeProcess.isSupported) {
				this.getPasswordHash(_controlPassword);
			} else {			
				this.onTorControlReady();
			}//else
		}//prepareTorProcess
		
		/**
		 * Attempts to launch the Tor process (binary). TorControl can communicate with a properly configured 
		 * Tor process even if it didn't launch it. Developers can bypass this method altogether if the Tor 
		 * process will be started manually. Be sure to update the TorControl <code>config</code> property 
		 * with any custom startup requirements.
		 * This function also starts listening to the Event.EXITING event on the native application object if
		 * the Tor process was successfully launched.
		 */
		private function launchTorProcess():void {			
			if (!this._launchServices) {
				this.onTorControlReady();
				return;
			}//if
			if (torProcess != null) {				
				this.onTorControlReady();
				return;
			}//if
			if (NativeProcess.isSupported) {
				try {					
					var launchInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
					var exeDirectory:File = File.applicationDirectory;
					var exeFile:File = File.applicationDirectory;
					var cfgFile:File = File.applicationStorageDirectory;				
					exeFile = exeFile.resolvePath(rootTorPath + executable);
					exeDirectory = exeDirectory.resolvePath(rootTorPath);				
					cfgFile = cfgFile.resolvePath(configFile);
					this.generateConfigFile(cfgFile); //Ensures that config data always exists as expected.
					launchInfo.executable = exeFile;
					launchInfo.workingDirectory = exeDirectory;
					launchInfo.arguments.push("-f");
					launchInfo.arguments.push(cfgFile.nativePath);
					torProcess = new NativeProcess();
					//Debug and log data are received over STDOUT
					torProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onStandardOutData);
					torProcess.start(launchInfo);
					NativeApplication.nativeApplication.addEventListener(Event.EXITING, this.stopTorProcess);
					this.onTorControlReady();
				} catch (err:*) {					
				}//catch
			} else {
				trace ("TorControl.launchTorProcess > NativeProcess is not supported. Tor must be started manually.");
				trace ("TorControl.launchTorProcess > You may also need to enable the \"Extended Desktop\" profile for your AIR application.");
				this.onTorControlReady();
			}//else
		}//launchTorProcess
		
		/**
		 * Stops a running Tor process, if one was started by TorContol. This function also stops listening to
		 * the Event.EXITING event on the native application object.
		 * 
		 * @param	eventObj
		 */
		public function stopTorProcess(... args):void {
			try {
				NativeApplication.nativeApplication.removeEventListener(Event.EXITING, this.stopTorProcess);
				if (torProcess == null) {
					return;
				}//if
				torProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, this.onStandardOutData);				
				this.sendRawControlMessage(TorControlModel.getControlMessage("shutdown")); 
				torProcess.exit(true); //Force close the process
				torProcess = null;
			} catch (err:*) {				
			}//catch
		}//stopTorProcess
		
		/**
		 * The IP of the Tor control socket (usually 127.0.0.1).
		 */
		public static function get controlIP():String {
			return (_controlIP);
		}//get controlIP
		
		/**
		 * The port of the Tor control socket (usually 9151).
		 */
		public static function get controlPort():int {
			return (_controlPort);
		}//get controlPort
		
		/**
		 * The IP of the Tor SOCKS proxy socket (usually 127.0.0.1).
		 */
		public static function get SOCKSIP():String {
			return (_SOCKSIP);
		}//get SOCKSIP
		
		/**
		 * The port of the Tor SOCKS proxy socket (usually 1080).
		 */
		public static function get SOCKSPort():int {
			return (_SOCKSPort);
		}//get SOCKSPort	
		
		/**
		 * The status of the Tor control connection: true=connected, false=not connected
		 */
		public static function get connected():Boolean {
			return (_connected);
		}//get connected
		
		/**
		 * The authentication status of the Tor control connection: true=authenticated, false=not authenticated
		 */
		public static function get authenticated():Boolean {
			return (_authenticated);
		}//get authenticated
		
		/**
		 * Establish a new Tor circuit through which future requests will be tunneled. Any existing tunnels will continue
		 * to use their existing circuits until disconnected.
		 */
		public function establishNewCircuit():void {
			if (connected && authenticated) {
				this.sendRawControlMessage(TorControlModel.getControlMessage("newcircuit")); 	
			}//if
		}//establishNewCircuit
		
		/**
		 * Generates the Tor config file from settings derived from various class properties (see near top of this class declaration).
		 * 
		 * @param	configFile The file to generate the config file to (output). This path should also be supplied to the Tor process
		 * at startup, if using TorControl to launch the Tor process.
		 */
		private function generateConfigFile(configFile:File):void {
			var stream:FileStream = new FileStream();
			stream.open(configFile, FileMode.WRITE);
			var configString:String = new String(configData.children()[0].toString());
			configString = this.replaceMeta(configString, "%control_ip%", String(_controlIP));
			configString = this.replaceMeta(configString, "%control_port%", String(_controlPort));
			configString = this.replaceMeta(configString, "%control_passhash%", String(_controlPasswordHash));
			configString = this.replaceMeta(configString, "%socks_ip%", String(_SOCKSIP));
			configString = this.replaceMeta(configString, "%socks_port%", String(_SOCKSPort));
			stream.writeMultiByte(configString, TorControlModel.charSetEncoding);			
			stream.close();
		}//generateConfigFile
		
		/**
		 * Handles STDOUT messages from the running Tor process. This ONLY works if TorControl is used to launch the Tor process.
		 * 
		 * @param	eventObj A ProgressEvent object.
		 */
		private function onStandardOutData(eventObj:ProgressEvent):void {
			var stdoutMsg:String = torProcess.standardOutput.readMultiByte(torProcess.standardOutput.bytesAvailable, TorControlModel.charSetEncoding);
			var event:TorControlEvent = new TorControlEvent(TorControlEvent.ONLOGMSG);
			event.body = stdoutMsg;			
			event.rawMessage = stdoutMsg;
			this.dispatchEvent(event);
		}//onStandardOutData
		
		/**
		 * Invoked when TorControl successfully connects to the (presumably) Tor control socket. Only after authentication
		 * should the socket be assumed to be a proper Tor control socket.
		 * 
		 * @param	eventObj An Event object.
		 */
		private function onConnect(eventObj:Event):void {			
			_connected = true;
			this.dispatchEvent(new TorControlEvent(TorControlEvent.ONCONNECT));
			this.authenticate();
		}//onConnect
		
		/**
		 * Invoked when TorControl receives an IOErrorEvent.
		 * 
		 * @param	eventObj An IOErrorEvent object.
		 */
		private function onConnectError(eventObj:IOErrorEvent):void {				
			_connected = false;
			var errorEventObj:TorControlEvent = new TorControlEvent(TorControlEvent.ONCONNECTERROR);
			errorEventObj.error = new TorASError(eventObj.toString());
			errorEventObj.error.status = eventObj.errorID;						
			errorEventObj.error.rawMessage = eventObj.toString();
			this.dispatchEvent(errorEventObj);
		}//onConnectError
		
		/**
		 * Invoked when TorControl receives an SecurityErrorEvent.
		 * 
		 * @param	eventObj An SecurityErrorEvent object.
		 */
		private function onConnectSecurityError(eventObj:IOErrorEvent):void {			
			_connected = false;
			var errorEventObj:TorControlEvent = new TorControlEvent(TorControlEvent.ONCONNECTERROR);
			errorEventObj.error = new TorASError(eventObj.toString());
			errorEventObj.error.status = eventObj.errorID;									
			errorEventObj.error.rawMessage = eventObj.toString();
			this.dispatchEvent(errorEventObj);
		}//onConnectSecurityError
		
		/**
		 * Send the authentication message to the Tor control socket.
		 */
		private function authenticate():void {
			_authenticated = false;
			if (this.usePasswordAuthentication) {
				var passwordAuthMsg:String = TorControlModel.getControlMessage("authenticate_password");
				passwordAuthMsg = passwordAuthMsg.split("%password%").join(_controlPassword);				
				this.sendRawControlMessage(passwordAuthMsg);				
			} else {
				this.sendRawControlMessage(TorControlModel.getControlMessage("authenticate"));
			}//else
		}//authenticate	
		
		private function get usePasswordAuthentication():Boolean {
			if ((_controlPassword != null) && (_controlPasswordHash != null) && (_controlPassword!="") && (_controlPasswordHash!="")) {
				return (true);
			}//if
			return (false);
		}//usePasswordAuthentication
		
		/**
		 * Sends a raw control message to the connected and authenticated control socket. The message must be a
		 * properly formatted Tor v1 Protocol string (https://gitweb.torproject.org/torspec.git?a=blob_plain;hb=HEAD;f=control-spec.txt).
		 * 
		 * @param	msg A Tor v1 Protocol-formatted control message (WITHOUT trailing linefeeds)
		 * 
		 * @return True if the message was sent successfully to the socket, false if the send failed (for example,
		 * not connected or authenticated).
		 */
		public function sendRawControlMessage(msg:String):Boolean {
			if ((!_socket) || (_socket == null)) {
				return (false);
			}//if
			this._synchResponseBuffer = "";
			this._synchRawResponseBuffer = "";
			msg = msg + TorControlModel.controlLineEnd;
			_socket.writeMultiByte(msg, TorControlModel.charSetEncoding);
			_socket.flush();
			return (true);
		}//sendRawControlMessage
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			var torEventType:String = null;
			if (TorControlEvent.isTorEvent(type)) {
				var torEventShortCode:String = TorControlEvent.getTorEventShortcode(type);				
				this.enableTorEvent(torEventShortCode);
			}//if
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);			
		}//addEventListener
		
		/**
		 * Enable a Tor control event (sent from the running process).
		 * 
		 * @param	eventType The internal Tor event type to listen for in a TorControlEvent.ONEVENT event (eee note below for more information).
		 * 
		 * @see https://gitweb.torproject.org/torspec.git?a=blob_plain;hb=HEAD;f=control-spec.txt (Section "4.1. Asynchronous events)
		 * 
		 */
		private function enableTorEvent(eventType:String):void {
			if ((!_socket) || (!_authenticated)) {
				return;
			}//if
			var torMessage:String = TorControlModel.getControlMessage("enableevent");
			this.addUniqueAsyncEvent(eventType);			
			torMessage = this.replaceMeta(torMessage, "%event_list%", this.enabledAsyncEventList);
			this.sendRawControlMessage(torMessage);
		}//enableTorEvent
		
		/**
		 * Disable a Tor control event (sent from the running process).
		 * 
		 * @param	eventType The internal Tor event type to stop listening for in a TorControlEvent.ONEVENT event (eee note below for more information).
		 * 
		 * @see https://gitweb.torproject.org/torspec.git?a=blob_plain;hb=HEAD;f=control-spec.txt (Section "4.1. Asynchronous events)
		 * 
		 */
		private function disableTorEvent(eventType:String):void {
			var torMessage:String = TorControlModel.getControlMessage("enableevent");
			this.removeAsyncEvent(eventType);			
			torMessage = this.replaceMeta(torMessage, "%event_list%", this.enabledAsyncEventList);
			this.sendRawControlMessage(torMessage);
		}//disableTorEvent
		
		/**
		 * Disables all Tor control events (sent from the running process).		 
		 */
		private function disableAllTorEvents():void {
			var torMessage:String = TorControlModel.getControlMessage("enableevent");
			 this._enabledEvents = new Array();			
			torMessage = this.replaceMeta(torMessage, "%event_list%", this.enabledAsyncEventList);
			this.sendRawControlMessage(torMessage);
		}//disableAllTorEvents
		
		private function get enabledAsyncEventList():String {
			var list:String = new String();
			for (var count:uint = 0; count < this._enabledEvents.length; count++) {
				var currentEvent:String = this._enabledEvents[count] as String;
				list += currentEvent + " ";
			}//for
			list=list.substr(0, (list.length-1))
			return (list);
		}//get enabledAsyncEventList
		
		private function addUniqueAsyncEvent(eventType:String):void {
			for (var count:uint = 0; count < this._enabledEvents.length; count++) {
				var currentEvent:String = this._enabledEvents[count] as String;
				if (currentEvent == eventType) {
					return;
				}//if
			}//for
			this._enabledEvents.push(eventType);
		}//addUniqueAsyncEvent
		
		private function removeAsyncEvent(eventType:String):void {
			var condensedEvents:Array = new Array();
			for (var count:uint = 0; count < this._enabledEvents.length; count++) {
				var currentEvent:String = this._enabledEvents[count] as String;
				if (currentEvent != eventType) {
					condensedEvents.push(currentEvent);
				}//if
			}//for
			this._enabledEvents = condensedEvents;
		}//removeAsyncEvent		
		
		private function onData(eventObj:ProgressEvent):void {
			var receivedMsg:String = _socket.readMultiByte(_socket.bytesAvailable, TorControlModel.charSetEncoding);			
			receivedMsg = receivedMsg.split(String.fromCharCode(10)).join("");
			var msgSplit:Array = receivedMsg.split(String.fromCharCode(13));
			for (var count:uint = 0; count < msgSplit.length; count++) {
				var currentLine:String = msgSplit[count] as String;
				var msgObj:Object = this.parseReceivedData(currentLine);
				if (msgObj.status == TorControlModel.asynchEventStatusCode) {					
					//Asynchronous notification;
					this._asynchEventBuffer += msgObj.body;
					this._asynchRawEventBuffer += receivedMsg;
					if (this.isMultilineMessage(msgObj.multilineStatusIndicator)) {						
						this._asynchEventBuffer += TorControlModel.controlLineEnd;
						this._asynchRawEventBuffer += TorControlModel.controlLineEnd;
					} else {						
						this.dispatchAsynchTorEvent(msgObj);
						this._asynchEventBuffer = "";
						this._asynchRawEventBuffer = "";
					}//else
					return;
				} else if ((!_authenticated) && (!TorControlModel.isControlResponseError(msgObj.status))) {
					//Authentication response					
					_authenticated = true;
					var event:TorControlEvent = new TorControlEvent(TorControlEvent.ONAUTHENTICATE);
					event.status = msgObj.status;
					event.body = msgObj.body;
					event.rawMessage = receivedMsg;
					this.dispatchEvent(event);
					return;
				} else {
					//Standard synchronous response			
					this._synchResponseBuffer += msgObj.body;
					this._synchRawResponseBuffer += receivedMsg;
					if (this.isMultilineMessage(msgObj.multilineStatusIndicator)) {
						this._synchResponseBuffer += TorControlModel.controlLineEnd;
						this._synchRawResponseBuffer += TorControlModel.controlLineEnd;
					} else {
						this.dispatchTorResponse(msgObj);
						this._synchResponseBuffer = "";
						this._synchRawResponseBuffer = "";
					}//else
				}//else
			}//for
		}//onData		
		
		private function isMultilineMessage(separator:String):Boolean {
			if (separator == " ") {
				return (false);
			} else {
				return (true);
			}//else
		}//isMultilineMessage
		
		private function dispatchAsynchTorEvent(msgObj:Object):void {
			try {
				var eventType:String = msgObj.body;				
				eventType = eventType.split(" ")[0] as String;							
				var torEventType:String = TorControlEvent.getTorEventLongcode(eventType);
				if (torEventType == null) {
					return;
				}//if				
				var event:TorControlEvent = new TorControlEvent(torEventType);
				event.status = msgObj.status;
				event.body = this._asynchEventBuffer.substr(eventType.length+1); //Strip out event type prefix + extra space following
				event.torEvent = eventType;
				event.rawMessage = this._asynchRawEventBuffer;
				this.dispatchEvent(event);
			} catch (err:*) {				
			}//catch
		}//dispatchAsynchTorEvent
		
		private function dispatchTorResponse(msgObj:Object):void {
			var event:TorControlEvent = new TorControlEvent(TorControlEvent.ONRESPONSE);
			event.status = msgObj.status;
			event.body = this._synchResponseBuffer;
			event.rawMessage = this._synchRawResponseBuffer;
			this.dispatchEvent(event);
		}//dispatchTorResponse
		
		private function parseReceivedData(dataStr:String):Object {
			var responseCodeStr:String = dataStr.substr(0, 3);
			var codeValue:int = new int(responseCodeStr);
			var multilineSeparator:String = dataStr.substr(3, 1);
			var responseBody:String = dataStr.substr(4);			
			var returnObj:Object = new Object();
			returnObj.status = codeValue;
			returnObj.multilineStatusIndicator = multilineSeparator;
			returnObj.body = responseBody;
			return (returnObj);
		}//parseReceivedData
		
		private function replaceMeta(input:String, meta:String, replace:String):String {
			return (input.split(meta).join(replace));
		}//replaceMeta		
		
	}//TorControl class

}//package