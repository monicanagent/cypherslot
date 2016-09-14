package org.torproject {
	
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	import flash.net.SecureSocket;	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;	
	import flash.events.SecurityErrorEvent;	
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	import org.torproject.events.SOCKS5TunnelEvent;
	import org.torproject.model.HTTPResponse;
	import org.torproject.model.HTTPResponseHeader;
	import org.torproject.model.SOCKS5Model;
	import org.torproject.model.TorASError;
	import flash.net.URLRequest;
	import flash.net.URLRequestDefaults;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import org.torproject.utils.URLUtil;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	
	//TLS/SSL support thanks to Henri Torgeman, a.k.a. Metal Hurlant  - https://code.google.com/p/as3crypto/
	import com.hurlant.crypto.tls.*;
	
	/**
	 * Provides SOCKS5-capable transport services for proxied network requests. This protocol is also used by Tor to transport
	 * various network requests.
	 * 
	 * Since TorControl is used to manage the Tor services process, if this process is already correctly configured and running
	 * SOCKS5Tunnel can be used completely independently (TorControl may be entirely omitted).
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
	 * 
	 * ---
	 * 
	 * This library incorporate the "as3crypto" library by Henri Torgeman. Additional licences for this libary and additionally
	 * incorporated source code are displayed below:
	 * 
	 * Copyright (c) 2007 Henri Torgemane
	 * All Rights Reserved.
	 * 
	 * BigInteger, RSA, Random and ARC4 are derivative works of the jsbn library
	 * (http://www-cs-students.stanford.edu/~tjw/jsbn/)
	 * The jsbn library is Copyright (c) 2003-2005  Tom Wu (tjw@cs.Stanford.EDU)
	 * 
	 * MD5, SHA1, and SHA256 are derivative works (http://pajhome.org.uk/crypt/md5/)
	 * Those are Copyright (c) 1998-2002 Paul Johnston & Contributors (paj@pajhome.org.uk)
	 * 
	 * SHA256 is a derivative work of jsSHA2 (http://anmar.eu.org/projects/jssha2/)
	 * jsSHA2 is Copyright (c) 2003-2004 Angel Marin (anmar@gmx.net)
	 * 
	 * AESKey is a derivative work of aestable.c (http://www.geocities.com/malbrain/aestable_c.html)
	 * aestable.c is Copyright (c) Karl Malbrain (malbrain@yahoo.com)
	 * 
	 * BlowFishKey, DESKey and TripeDESKey are derivative works of the Bouncy Castle Crypto Package (http://www.bouncycastle.org)
	 * Those are Copyright (c) 2000-2004 The Legion Of The Bouncy Castle
	 * 
	 * Base64 is copyright (c) 2006 Steve Webster (http://dynamicflash.com/goodies/base64)
	 * 
	 * Redistribution and use in source and binary forms, with or without modification, 
	 * are permitted provided that the following conditions are met:
	 * 
	 * Redistributions of source code must retain the above copyright notice, this list 
	 * of conditions and the following disclaimer. Redistributions in binary form must 
	 * reproduce the above copyright notice, this list of conditions and the following 
	 * disclaimer in the documentation and/or other materials provided with the distribution.
	 * 
	 * Neither the name of the author nor the names of its contributors may be used to endorse
	 * or promote products derived from this software without specific prior written permission.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
	 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
	 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  
	 * 
	 * IN NO EVENT SHALL TOM WU BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
	 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER
	 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF
	 * THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT
	 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
	 * 
	 * ---
	 * 
	 * Additionally, the MD5 algorithm is covered by the following notice:
	 * Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All rights reserved.
	 * 
	 * License to copy and use this software is granted provided that it
	 * is identified as the "RSA Data Security, Inc. MD5 Message-Digest
	 * Algorithm" in all material mentioning or referencing this software
	 * or this function.
	 * 
	 * License is also granted to make and use derivative works provided
	 * that such works are identified as "derived from the RSA Data
	 * Security, Inc. MD5 Message-Digest Algorithm" in all material
	 * mentioning or referencing the derived work.
	 * 
	 * RSA Data Security, Inc. makes no representations concerning either
	 * the merchantability of this software or the suitability of this
	 * software for any particular purpose. It is provided "as is"
	 * without express or implied warranty of any kind.
	 * 
	 * These notices must be retained in any copies of any part of this
	 * documentation and/or software.
 	 */
	public class SOCKS5Tunnel extends EventDispatcher {
		
		/**
		 * Default SOCKS5 IP address. For Tor networking, this is usually 127.0.0.1 (the current local machine).
		 */
		public static const defaultSOCKSIP:String = "127.0.0.1";
		/**
		 * Default SOCKS5 port.
		 */
		public static const defaultSOCKSPort:int = 1080;
		/**
		 * Maximum number of redirects to follow, if enabled, whenever a 301 or 302 HTTP status is received.
		 */
		public static const maxRedirects:int = 5;
		private var _tunnelSocket:Socket = null;
		private var _secureTunnelSocket:TLSSocket = null;
		private var _tunnelIP:String = null;
		private var _tunnelPort:int = -1;
		private var _connectionType:int = -1;
		private var _connected:Boolean = false;
		private var _authenticated:Boolean = false;
		private var _tunneled:Boolean = false;		
		private var _requestActive:Boolean = false;
		private var _requestBuffer:Array = new Array();
		private var _responseBuffer:ByteArray = new ByteArray();
		private var _HTTPStatusReceived:Boolean = false;
		private var _HTTPHeadersReceived:Boolean = false;
		private var _HTTPResponse:HTTPResponse;		
		private var _currentRequest:URLRequest;
		private var _redirectCount:int = 0;	
		private var _timeoutID:uint;
		
		/**
		 * Creates an instance of a SOCKS5 proxy tunnel.
		 * 
		 * @param	tunnelIPSet The SOCKS proxy IP to use. If not specified, the current default value is used.
		 * @param	tunnelPortSet The SOCKS proxy port to use. If not specified, the current default value is used.
		 */
		public function SOCKS5Tunnel(tunnelIPSet:String=null, tunnelPortSet:int=-1) {
			if (tunnelIPSet == null) {
				this._tunnelIP = defaultSOCKSIP;
			} else {
				this._tunnelIP = tunnelIPSet;
			}
			if (tunnelPortSet < 1) {
				this._tunnelPort = defaultSOCKSPort;
			} else {
				this._tunnelPort = tunnelPortSet;
			}			
		}//constructor
		
		/**
		 * The current SOCKS proxy tunnel IP being used by the instance.
		 */
		public function get tunnelIP():String {
			return (this._tunnelIP);
		}//get tunnelIP
		
		/**
		 * The current SOCKS proxy tunnel port being used by the instance.
		 */
		public function get tunnelPort():int {
			return (this._tunnelPort);
		}//get tunnelPort		
		
		/**
		 * The tunnel connection type being managed by this instance.
		 */
		public function get connectionType():int {
			return (this._connectionType);
		}//get connectionType
		
		/**
		 * The status of the tunnel connection (true=connected, false=not connected). Requests
		 * cannot be sent through the proxy unless it is both connected and tunneled.
		 */
		public function get connected():Boolean {
			return (this._connected);
		}//get connected
		
		/**
		 * The status of the proxy tunnel (true=ready, false=not ready). Requests
		 * cannot be sent through the proxy unless it is both connected and tunneled.
		 */
		public function get tunneled():Boolean {
			return (this._tunneled);
		}//get tunneled
			
		/**
		 * Sends a HTTP request through the socks proxy, sending any included information (such as form data) in the process. Additional
		 * requests via this tunnel connection will be disallowed until this one has completed (since replies may be multi-part).
		 * 
		 * @param request The URLRequest object holding the necessary information for the request.
		 * @param timeout The amount of time, in milliseconds, before the request times out. A request times out when a full response
		 * (header + body) is not fully received. Default is 30000 (30 seconds).
		 * 
		 * @return True if the request was dispatched successfully, false otherwise.
		 */
		public function loadHTTP(request:URLRequest, timeout:Number=30000):Boolean {
			if (request == null) {
				return (false);
			}//if	
			try {			 
				this._requestBuffer.push(request);			
				//this._currentRequest = request;
				this._responseBuffer = new ByteArray();
				this._HTTPStatusReceived = false;
				this._HTTPHeadersReceived = false;				
				this.disconnectSocket();
				this._HTTPResponse = new HTTPResponse();
				this._connectionType = SOCKS5Model.SOCKS5_conn_TCPIPSTREAM;			
				this._tunnelSocket = new Socket();				
				this.addSocketListeners();
				trace ("request timeout " + timeout);
				this._timeoutID=setTimeout(this.onRequestTimeout, timeout, request);
				this._tunnelSocket.connect(this.tunnelIP, this.tunnelPort);
				return (true);
			} catch (err:*) {
				var eventObj:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONCONNECTERROR);
				eventObj.error = new TorASError(err.toString());
				eventObj.error.rawMessage = err.toString();
				this.dispatchEvent(eventObj);
				return (false);
			}//catch
			return (false);
		}//loadHTTP				
		
		/**
		 * Invoked when a tunnelled request times out (full response is not received within a specified time limit).
		 */
		public function onRequestTimeout(requestObj:URLRequest):void {
			trace ("SOCKS5Tunnel timedout");
			var eventObj:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONTIMEOUT);
			eventObj.request = requestObj;
			this.dispatchEvent(eventObj);
		}
		
		/**
		 * The currently active HTTP/HTTPS request being handled by the tunnel instance.
		 */
		public function get activeRequest():* {
			return (this._currentRequest);
		}//get activeRequest
		
		/**
		 * Attempts to establish a new Tor circuit through a running TorControl instance. 
		 * Future SOCKS5Tunnel instances will communicate through the new circuit while 
		 * existing and connected instances will continue to communicate through their existing circuits until closed.
		 * A TorControl instance must be instantiated and fully initialized before attempting to invoke this command.
		 * 
		 * @return True if TorControl is active and could be invoked to establish a new circuit, false
		 * if the invocation failed for any reason.
		 */
		public function establishNewCircuit():Boolean {
			try {
				//Dynamically evaluate so that there are no dependencies
				var tcClass:Class = getDefinitionByName("org.torproject.TorControl") as Class;
				if (tcClass == null) {
					return (false);
				}//if
				var tcInstance:*= new tcClass();
				if (tcClass.connected && tcClass.authenticated) {
					tcInstance.establishNewCircuit();
					return (true);
				}//if
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//establishNewCircuit
		
		/**
		 * Disconnects the SOCKS5 tunnel socket if connected.
		 */
		private function disconnectSocket():void {				
			this._connected = false;
			this._authenticated = false;
			this._tunneled = false;			
			if (this._tunnelSocket != null) {
				this.removeSocketListeners();
				if (this._tunnelSocket.connected) {
					this._tunnelSocket.close();
				}//if
				this._tunnelSocket = null;
				var eventObj:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONDISCONNECT);
				this.dispatchEvent(eventObj);
			}//if			
		}//disconnectSocket
		
		/**
		 * Removes standard listeners to the default SOCKS5 tunnel socket.
		 */
		private function removeSocketListeners():void {
			if (this._tunnelSocket == null) { return;}
			this._tunnelSocket.removeEventListener(Event.CONNECT, this.onTunnelConnect);
			this._tunnelSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onTunnelConnectError);
			this._tunnelSocket.removeEventListener(IOErrorEvent.IO_ERROR, this.onTunnelConnectError);
			this._tunnelSocket.removeEventListener(IOErrorEvent.NETWORK_ERROR, this.onTunnelConnectError);
			this._tunnelSocket.removeEventListener(ProgressEvent.SOCKET_DATA, this.onTunnelData);	
			this._tunnelSocket.removeEventListener(Event.CLOSE, this.onTunnelDisconnect);
		}//removeSocketListeners
				
		/**
		 * Adds standard listeners to the default SOCKS5 tunnel socket.
		 */
		private function addSocketListeners():void {
			if (this._tunnelSocket == null) { return;}
			this._tunnelSocket.addEventListener(Event.CONNECT, this.onTunnelConnect);
			this._tunnelSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onTunnelConnectError);
			this._tunnelSocket.addEventListener(IOErrorEvent.IO_ERROR, this.onTunnelConnectError);
			this._tunnelSocket.addEventListener(IOErrorEvent.NETWORK_ERROR, this.onTunnelConnectError);			
			this._tunnelSocket.addEventListener(Event.CLOSE, this.onTunnelDisconnect);
		}//addSocketListeners
		
		/**
		 * Invoked when the SOCKS5 tunnel socket connection is successfully established.
		 * 
		 * @param	eventObj A standard Event object.
		 */
		private function onTunnelConnect(eventObj:Event):void {				
			this._connected = true;
			this._tunnelSocket.removeEventListener(Event.CONNECT, this.onTunnelConnect);			
			this._tunnelSocket.addEventListener(ProgressEvent.SOCKET_DATA, this.onTunnelData);			
			var connectEvent:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONCONNECT);
			this.dispatchEvent(connectEvent);
			this.authenticateTunnel();
		}//onTunnelConnect	
		
		/**
		 * Invoked when the SOCKS5 tunnel receives an IOErrorEvent event.
		 * 
		 * @param	eventObj A standard IOErrorEvent object.
		 */
		private function onTunnelConnectError(eventObj:IOErrorEvent):void {			
			this.removeSocketListeners();
			this._tunnelSocket = null;
			this._connected = false;
			this._authenticated = false;
			this._tunneled = false;
			var errorEventObj:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONCONNECTERROR);
			errorEventObj.error = new TorASError(eventObj.toString());
			errorEventObj.error.status = eventObj.errorID;						
			errorEventObj.error.rawMessage = eventObj.toString();
			this.dispatchEvent(errorEventObj);
		}//onTunnelConnectError
		
		/**
		 * Invoked when the SOCKS5 tunnel socket has been disconnected.
		 * 
		 * @param	eventObj A standard Event object.
		 */
		private function onTunnelDisconnect(eventObj:Event):void {				
			this.removeSocketListeners();			
			this._connected = false;
			this._authenticated = false;
			this._tunneled = false;			
			this._tunnelSocket = null;			
			var disconnectEvent:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONDISCONNECT);
			this.dispatchEvent(disconnectEvent);			
		}//onTunnelDisconnect			
		
		/**
		 * Invoked to authenticate the SOCKS5 tunnel after it is connected. The tunnel will not accept any outbound 
		 * requests until authentication has been completed.
		 * 
		 * Note: Currently only the 0 (none) authentication type is supported. 
		 */
		private function authenticateTunnel():void {			
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_head_VERSION);
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_auth_NUMMETHODS);
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_auth_NOAUTH);			
			this._tunnelSocket.flush();
		}//authenticateTunnel
		
		/**
		 * Invoked when the SOCKS5 tunnel authentication has completed and the end-to-end connection is ready to be established.
		 */
		private function onAuthenticateTunnel():void {				
			var currentRequest:* = this._requestBuffer[0];
			//var currentRequest:*= this._requestBuffer;
			if (currentRequest is URLRequest) {
				this.establishHTTPTunnel();
			}//if
		}//onAuthenticateTunnel
		
		/**
		 * Establishes a HTTP/HTTPS tunnel once the SOCKS5 socket has been connected and authenticated. If no port is specified,
		 * HTTP connections will be attempted over port 80 while HTTPS connections will be attempted over port 443.
		 */
		private function establishHTTPTunnel():void {			
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_head_VERSION);
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_conn_TCPIPSTREAM);
			this._tunnelSocket.writeByte(0); //Reserved
			this._tunnelSocket.writeByte(SOCKS5Model.SOCKS5_addr_DOMAIN); //Most secure when using DNS through proxy
			var currentRequest:* = this._requestBuffer[0];			
			//var currentRequest:*= this._currentRequest;
			var domain:String = URLUtil.getServerName(currentRequest.url);
			/*
			var domainSplit:Array = domain.split(".");			
			if (domainSplit.length>2) {
				domain = domainSplit[1] + "." + domainSplit[2]; //Ensure we have JUST the domain
			}//if				
			*/
			var domainLength:int = int(domain.length);
			var port:int = int(URLUtil.getPort(currentRequest.url));			
			this._tunnelSocket.writeByte(domainLength);
			var portMSB:int = (port & 0xFF00) >> 8;
			var portLSB:int = port & 0xFF;			
			this._tunnelSocket.writeMultiByte(domain, SOCKS5Model.charSetEncoding);			
			this._tunnelSocket.writeByte(portMSB);
			this._tunnelSocket.writeByte(portLSB);			
			this._tunnelSocket.flush();			
		}//establishHTTPTunnel
		
		/**
		 * Invoked when the SOCKS5 tunnel has been established (connected and authenticated).
		 */
		private function onEstablishTunnel():void {				
			var currentRequest:* = this._requestBuffer[0];
			//var currentRequest:*= this._currentRequest;
			//URLRequest handles HTTP/HTTPS requests...
			if (currentRequest is URLRequest) {
				this.sendQueuedHTTPRequest();
			}//if		
		}//onEstablishHTTPTunnel
		
		/**
		 * Sends the next queued HTTP/HTTPS request. Requests are queued whenever a connection has not yet been established or 
		 * authentication is not yet complete.
		 */
		private function sendQueuedHTTPRequest():void {			
			//var currentRequest:URLRequest = this._requestBuffer.shift() as URLRequest;
			//this._currentRequest = currentRequest;			
			this._currentRequest = this._requestBuffer[0];
			if (URLUtil.isHttpsURL(this._currentRequest.url)) {
				this.startTLSTunnel();
			} else {
				if (this._HTTPResponse!=null ) {
					if (this._currentRequest.manageCookies) {
						var requestString:String = SOCKS5Model.createHTTPRequestString(this._currentRequest, this._HTTPResponse.cookies);		
					} else {
						requestString = SOCKS5Model.createHTTPRequestString(this._currentRequest, null);
					}//else
				} else {
					requestString = SOCKS5Model.createHTTPRequestString(this._currentRequest, null);
				}//else
				this._HTTPResponse = new HTTPResponse();
				this._tunnelSocket.writeMultiByte(requestString, SOCKS5Model.charSetEncoding);				
				this._tunnelSocket.flush();
			}//else
		}//sendQueuedHTTPRequest
		
		/**
		 * Starts TLS for HTTPS requests/responses.
		 */
		private function startTLSTunnel():void {			
			if (this._HTTPResponse!=null ) {
				if (this._currentRequest.manageCookies) {
					var requestString:String = SOCKS5Model.createHTTPRequestString(this._currentRequest, this._HTTPResponse.cookies);		
				} else {
					requestString = SOCKS5Model.createHTTPRequestString(this._currentRequest, null);
				}//else
			} else {
				requestString = SOCKS5Model.createHTTPRequestString(this._currentRequest, null);
			}//else
			this._HTTPResponse = new HTTPResponse();		
			var domain:String = URLUtil.getServerName(this._currentRequest.url);
			this._secureTunnelSocket = new TLSSocket();
			this._tunnelSocket.removeEventListener(ProgressEvent.SOCKET_DATA, this.onTunnelData);	
			this._secureTunnelSocket.addEventListener(ProgressEvent.SOCKET_DATA, this.onTunnelData);
			this._secureTunnelSocket.startTLS(this._tunnelSocket, domain);
			this._secureTunnelSocket.writeMultiByte(requestString, SOCKS5Model.charSetEncoding); //This is queued to send on connect
		}//startTLSTunnel		
		
		/**
		 * Tests whether or not the SOCKS5 authentication request was successful.
		 * 
		 * @param	respData The raw response data to analyze.
		 * 
		 * @return True if the response confirms that authentication was successful, false otherwise.
		 */
		private function authResponseOkay(respData:ByteArray):Boolean {
			respData.position = 0;
			var SOCKSVersion:int = respData.readByte();
			var authMethod:int = respData.readByte();
			if (SOCKSVersion != SOCKS5Model.SOCKS5_head_VERSION) {
				return (false);
			}//if
			if (authMethod != SOCKS5Model.SOCKS5_auth_NOAUTH) {
				return (false);
			}//if			
			return (true);
		}//authResponseOkay
		
		/**
		 * Tests whether or not the SOCKS5 response indicates that the tunnel has been established and is ready for communication.
		 * 
		 * @param	respData The raw SOCKS5 response message to analyze.
		 * 
		 * @return True if the SOCKS5 tunnel is ready to proxy requests and responses, false otherwise.
		 */
		private function tunnelResponseOkay(respData:ByteArray):Boolean {
			respData.position = 0;
			var currentRequest:* = this._requestBuffer[0];
			if (currentRequest is URLRequest) {
				var SOCKSVersion:int = respData.readByte();
				var status:int = respData.readByte();
				if (SOCKSVersion != SOCKS5Model.SOCKS5_head_VERSION) {
					return (false);
				}//if
				if (status != 0) {
					return (false);
				}//if
				return (true);
			}//if
			return (false);
		}//tunnelResponseOkay
		
		/**
		 * Tests whether or not the SOCKS5 response data indicates that the entire HTTP/HTTPS request and response are complete.
		 * 
		 * @param	respData The raw SOCKS5 data to analyze.
		 * 
		 * @return True if the tunneled transaction appears to be complete, false otherwise.
		 */
		private function tunnelRequestComplete(respData:ByteArray):Boolean {			
			var bodySize:int = -1;
			if (this._HTTPHeadersReceived) {
				try {
					//If content length header supplied, use it to determine if response body is fully completed...
					bodySize = int(this._HTTPResponse.getHeader("Content-Length").value);
					if (bodySize>-1) {
						var bodyReceived:int = this._HTTPResponse.body.length;												
						if (bodySize != bodyReceived) {
							return (false);
						}//if
						return (true);
					}//if
				} catch (err:*) {
					bodySize = -1;
				}//catch
			}//if		
			//Content-Length header not found so using raw data length instead...
			respData.position = respData.length - 4; //Not bytesAvailable since already read at this point!
			var respString:String = respData.readMultiByte(4, SOCKS5Model.charSetEncoding);			
			respData.position = 0;
			if (respString == SOCKS5Model.doubleLineEnd) {
				return (true);
			}//if
			return (false);
		}//tunnelRequestComplete
		
		/**
		 * Handles a HTTP redirect (301 or 302 response code).
		 * 
		 * @param	responseObj The HTTPResponse object to analyze for redirection information.
		 * 
		 * @return True if the supplied response is a redirect and the redirect was automatically handled, false otherwise.
		 */
		private function handleHTTPRedirect(responseObj:HTTPResponse):Boolean {
			this._currentRequest = _requestBuffer[0] as URLRequest;
			if (this._currentRequest.followRedirects) {				
				if ((responseObj.statusCode == 301) || (responseObj.statusCode == 302)) {					
					var redirectInfo:HTTPResponseHeader = responseObj.getHeader("Location");						
					if (redirectInfo != null) {		
						this._redirectCount++;						
						this._currentRequest.url = redirectInfo.value;
						this._HTTPStatusReceived = false;
						this._HTTPHeadersReceived = false;											
						this._responseBuffer = new ByteArray();
						if (this._redirectCount >= maxRedirects) {
							//Maximum redirects hit
							var statusEvent:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONHTTPMAXREDIRECTS);			
							statusEvent.httpResponse = this._HTTPResponse;						
							this.dispatchEvent(statusEvent);							
							this.disconnectSocket();
							return (true);							
						}//if
						this._requestBuffer.push(this._currentRequest);
						statusEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONHTTPREDIRECT);			
						statusEvent.httpResponse = this._HTTPResponse;						
						this.dispatchEvent(statusEvent);	
						this.sendQueuedHTTPRequest();
						return (true);
					}//if
				}//if				
			}//if
			return (false);
		}//handleHTTPRedirect			
		
		/**
		 * Handles a raw, partial or complete HTTP response. This method also handles HTTPS responses after decryption using the same
		 * mechanisms.
		 * 
		 * @param	rawData The raw HTTP data to analyze and process.		 
		 * @param	secure Used with the SOCKS5TunnelEvent dispatched by this method to inform listeners whether or not the response is secure (HTTPS).
		 */
		private function handleHTTPResponse(rawData:ByteArray, secure:Boolean = false):void {
			rawData.readBytes(this._responseBuffer, this._responseBuffer.length);			
			if (!this._HTTPStatusReceived) {				
				if (this._HTTPResponse.parseResponseStatus(this._responseBuffer)) {
					this._HTTPStatusReceived = true;
					var statusEvent:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONHTTPSTATUS);			
					statusEvent.httpResponse = this._HTTPResponse;						
					this.dispatchEvent(statusEvent);												
				}//if
			}//if
			if (!this._HTTPHeadersReceived) {			
				if (this._HTTPResponse.parseResponseHeaders(this._responseBuffer)) {
					this._HTTPHeadersReceived = true;
					statusEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONHTTPHEADERS);			
					statusEvent.httpResponse = this._HTTPResponse;
					this.dispatchEvent(statusEvent);						
				}//if
			}//if				
			if (this.handleHTTPRedirect(this._HTTPResponse)) {
				return;
			}//if
			this._responseBuffer.position = 0;				
			this._HTTPResponse.parseResponseBody(this._responseBuffer);
			this._responseBuffer.position = 0;			
			if (!this.tunnelRequestComplete(rawData)) {
				//Response not yet fully received...keep waiting.				
				return;
			}//if
			//Response fully received.
			clearTimeout(this._timeoutID);
			this._timeoutID = 0;
			var dataEvent:SOCKS5TunnelEvent = new SOCKS5TunnelEvent(SOCKS5TunnelEvent.ONHTTPRESPONSE);		
			dataEvent.request = this._requestBuffer.shift();;
			dataEvent.secure = secure;			
			dataEvent.httpResponse = this._HTTPResponse;	
			dataEvent.httpResponse.rawResponse = new ByteArray();
			dataEvent.httpResponse.rawResponse.writeBytes(this._responseBuffer);
			this.disconnectSocket();			
			this.dispatchEvent(dataEvent);	
			this._responseBuffer = new ByteArray();		
			this._HTTPStatusReceived = false;
			this._HTTPHeadersReceived = false;			
		}//handleHTTPResponse		
		
		/**
		 * Handles raw HTTP/HTTPS data from the SOCKS5 tunnel socket. Authentication, tunnel establishment, and message 
		 * parsing branching (how responses are interpreted), are all handled automatically in this method.
		 * 
		 * @param	eventObj A standard ProgressEvent event (usually from an active Socket instance).
		 */
		private function onTunnelData(eventObj:ProgressEvent):void {
			var rawData:ByteArray = new ByteArray();
			var stringData:String = new String();			
			if (eventObj.target is Socket) {
				//Direct socket
				this._tunnelSocket.readBytes(rawData);	
			} else {
				//TLS pseudo-socket
				this._secureTunnelSocket.readBytes(rawData);
			}//else
			rawData.position = 0;
			stringData = rawData.readMultiByte(rawData.length, SOCKS5Model.charSetEncoding);					
			rawData.position = 0;
			//_authenticated and _tunneled flags are set for all outgoing connections...
			if (!this._authenticated) {
				if (this.authResponseOkay(rawData)) {
					this._authenticated = true;
					this.onAuthenticateTunnel();					
					return;
				}//if
			}//if			
			if (!this._tunneled) {
				if (this.tunnelResponseOkay(rawData)) {
					this._tunneled = true;					
					this.onEstablishTunnel();
					return;
				}//if
			}//if
			//Since the tunnel can handle all types of connections, this is where we decide how responses are handled...
			//if (this._currentRequest is URLRequest) {
			if (this._requestBuffer[0] is URLRequest) {				
				if (eventObj.target is Socket) {					
					this.handleHTTPResponse(rawData, false);
				}//if
				if (eventObj.target is TLSSocket) {										
					this.handleHTTPResponse(rawData, true);
				}//if
			}//if
		}//onTunnelData
		
	}//SOCKS5Tunnel class

}//package