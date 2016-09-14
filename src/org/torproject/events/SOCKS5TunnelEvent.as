package org.torproject.events {
	
	import flash.events.Event;
	import flash.net.URLRequest;
	import org.torproject.model.HTTPResponse;
	import org.torproject.model.TorASError;
	import flash.utils.ByteArray;
	
	/**
	 * Contains data and information from various events raised within a SOCKS5Tunnel instance.
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
	public class SOCKS5TunnelEvent extends Event {
		
		/**
		 * Dispatched when the SOCKS5Tunnel instance successfully connects to the tunnel socket.
		 */
		public static const ONCONNECT:String = "Event.SOCKS5TunnelEvent.ONCONNECT";
		/**
		 * Dispatched when the SOCKS5Tunnel instance experiences an error in connecting to the tunnel socket.
		 */
		public static const ONCONNECTERROR:String = "Event.SOCKS5TunnelEvent.ONCONNECTERROR";
		/**
		 * Dispatched when the SOCKS5Tunnel request times out.
		 */
		public static const ONTIMEOUT:String = "Event.SOCKS5TunnelEvent.ONTIMEOUT";
		/**
		 * Dispatched when the SOCKS5Tunnel instance successfully authenticates the tunnel socket. Tunnel requests
		 * are available after this event is dispatched.
		 */
		public static const ONAUTHENTICATE:String = "Event.SOCKS5TunnelEvent.ONAUTHENTICATE";
		/**
		 * Dispatched when the SOCKS5Tunnel instance disconnects from the tunnel socket.
		 */
		public static const ONDISCONNECT:String = "Event.SOCKS5TunnelEvent.ONDISCONNECT";
		/**
		 * Dispatched when the SOCKS5Tunnel instance received a complete response to a tunneled HTTP request. Both non-secure
		 * and secure (TLS / SSL) requests and responses are handled with the same event. Since the data will be transparently
		 * encrypted and descrypted, use the "secure" property of the event to determine if the data is secured or not.
		 * In a typical response, status would be parsed first, followed by headers, and finally by this event.
		 */
		public static const ONHTTPRESPONSE:String = "Event.SOCKS5TunnelEvent.ONHTTPRESPONSE";
		/**
		 * Dispatched when the SOCKS5Tunnel instance receives a 301 or 302 (redirect) HTTP response and the URLRequest
		 * used to initiate the request includes the followRedirects property as true. If enabled, the redirected request is
		 * sent immediately following this event and includes any cookies specified in the redirect response (unless this is disabled).
		 */
		public static const ONHTTPREDIRECT:String = "Event.SOCKS5TunnelEvent.ONHTTPREDIRECT";
		/**
		 * Dispatched when the SOCKS5Tunnel instance has done more than the maximum number of automated redirects (default is 5).
		 */
		public static const ONHTTPMAXREDIRECTS:String = "Event.SOCKS5TunnelEvent.ONHTTPMAXREDIRECTS";
		/**
		 * Dispatched when the SOCKS5Tunnel instance receives enough information to parse HTTP headers from a response.
		 * In a typical response, status would be parsed first, followed by headers, and finally by the ONHTTPRESPONSE event.
		 */
		public static const ONHTTPHEADERS:String = "Event.SOCKS5TunnelEvent.ONHTTPHEADERS";
		/**
		 * Dispatched when the SOCKS5Tunnel instance receives enough information to parse HTTP status information from a response.
		 * In a typical response, headers would be parsed next, followed by the ONHTTPRESPONSE event.
		 */
		public static const ONHTTPSTATUS:String = "Event.SOCKS5TunnelEvent.ONHTTPSTATUS";
		
		/**
		 * The current, or completed, HTTP/S response received from the server.
		 */
		public var httpResponse:HTTPResponse = null;
		/**
		 * True if the request/response was secure (TLS / SSL).
		 */
		public var secure:Boolean = false;
		/**
		 * Any error encountered with the request / response.
		 */
		public var error:TorASError = null;	
		/**
		 * Original HTTP/s request object.
		 */
		public var request:URLRequest;
		
		public function SOCKS5TunnelEvent(p_type:String, p_bubbles:Boolean = false, p_cancelable:Boolean = false) {			
			super(p_type, p_bubbles, p_cancelable);
		}//consructor
		
	}//SOCKS5TunnelEvent

}//package