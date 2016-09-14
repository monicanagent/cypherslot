package org.torproject.model {
	
	import flash.net.URLRequest;
	import flash.net.URLRequestDefaults;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import org.torproject.utils.URLUtil;	
	
	/**
	 * Stores protocol lookup, message construction, and other information for use with the SOCKS5 tunnel connection.
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
	public class SOCKS5Model {
		
		public static const charSetEncoding:String = "iso-8859-1";
		public static const HTTP_request_prefix:String = "HTTP";
		public static const HTTP_version:String = "1.1";
		public static const HTTP_cookie_header:String = "Cookie: ";
		public static const lineEnd:String = String.fromCharCode(13) + String.fromCharCode(10);
		public static const doubleLineEnd:String = lineEnd+lineEnd;		
		
		//SOCKS5 version header (maybe support 4 some day?)
		public static const SOCKS5_head_VERSION:int = 5;
		
		// Authentication type constants
		public static const SOCKS5_auth_NUMMETHODS:int = 1; //Number of authentication methods supported (currently only one: NOAUTH)
		public static const SOCKS5_auth_NOAUTH:int = 0; //None
		public static const SOCKS5_auth_GSSAPI:int = 1; //GSSAPI
		public static const SOCKS5_auth_USER:int = 2; //Username & password
		
		//Connection type constants				
		public static const SOCKS5_conn_TCPIPSTREAM:int = 1; //TCP/IP streaming connection
		public static const SOCKS5_conn_TCPIPPORT:int = 2; //TCP/IP port binding (listening)
		public static const SOCKS5_conn_UDPPORT:int = 3; //UDP port binding
		
		//Address type constants				
		public static const SOCKS5_addr_IPV4:int = 1; //IPv4 address type
		public static const SOCKS5_addr_DOMAIN:int = 3; //Domain address type
		public static const SOCKS5_addr_IPV6:int = 4; //IPv6 address type
		
		//Connection response constants				
		public static const SOCKS5_resp_OK:int = 0; //OK response code
		public static const SOCKS5_resp_FAIL:int = 1; //General failure
		public static const SOCKS5_resp_NOTALLOWED:int = 2; //Connection not allowed
		public static const SOCKS5_resp_NETERROR:int = 3; //Network unreachable
		public static const SOCKS5_resp_HOSTERROR:int = 4; //Host unreachable
		public static const SOCKS5_resp_REFUSED:int = 5; //Connection refused
		public static const SOCKS5_resp_TTLEXP:int = 6; //TTL expired
		public static const SOCKS5_resp_CMDERROR:int = 7; //Command not supported
		public static const SOCKS5_resp_ADDRERROR:int = 8; //Address type not supported
		
		
		/**
		 * Creates a complete HTTP request string, complete with headers.
		 * 
		 * @param	request The URLRequest object to parse and create the request from.
		 * @param   cookies An optional vector of HTTPCookie objects to send with the request. These will be appended to the header data.
		 * 
		 * @return A valid, complete HTTP request including request headers, etc., or null if one couldn't be created.
		 * 
		 */
		public static function createHTTPRequestString(request:URLRequest, cookies:Vector.<HTTPCookie>=null):String {
			if (request == null) {
				return (null);
			}//if
			//Request begin
			var returnString:String = new String();
			//GET data
			request.url = request.url+appendGETData(request);
			returnString = request.method + " " + URLUtil.getResourcePath(request.url) + " " + HTTP_request_prefix + "/" + HTTP_version + lineEnd;			
			//Headers
			returnString += "User-Agent: " + URLRequestDefaults.userAgent + lineEnd;
			returnString += "Host: " + URLUtil.getServerName(request.url) + lineEnd;		
			//Cookies
			if (request.manageCookies) {
				returnString += appendHeaderCookies(cookies);		
			}//if
			for (var count:uint = 0; count < request.requestHeaders.length; count++) {
				var currentHeader:URLRequestHeader = request[count] as URLRequestHeader;
				returnString += currentHeader.name + ": " + currentHeader.value + lineEnd;
			}//for
			//POST data
			var appendPostData:String = appendPOSTData(request);
			if (request.method == URLRequestMethod.POST) {
				returnString += "Content-Type: " + contentEncodingType(request.data) + lineEnd;
				returnString += "Content-Length: " + String(appendPostData.length) + lineEnd;				
				returnString +=  lineEnd + appendPostData;
			}//if
			//Request end
			returnString += lineEnd + lineEnd;
			return (returnString);			
		}//createHTTPRequestString
		
		private static function contentEncodingType(data:*):String {
			//Other types to be implemented for binary, XML, etc.	
			return ("application/x-www-form-urlencoded");			
		}//contentEncodingType
		
		/**
		 * Creates a string from supplied data to be appended to a HTTP GET request.
		 * 
		 * @param	data The URLRequest from which to extrapolate GET data to send.		 
		 * 
		 * @return The URL GET data to be appended to the request.
		 */
		private static function appendGETData(request:URLRequest):String {
			var returnString:String = new String();
			returnString = "";
			if (request == null) {
				return (returnString);
			}//if
			
			if (request.method != URLRequestMethod.GET) {
				return (returnString);
			}//if
			var tempURL:String = request.url;
			var data:*= request.data;
			if (data is URLVariables) {
				var vars:URLVariables = data as URLVariables;
				for (var item:* in vars) {
					returnString += GETDataPrefix(tempURL) + encodeURIComponent(item) + "=" + encodeURIComponent(vars[item]);
					tempURL += returnString;
				}//for
				return (returnString);
			}//if			
			if (data is ByteArray) {
				//Adobe doesn't support this, but we can -- unless there's a good reason not to?
				returnString += ByteArray(data).readMultiByte(0, charSetEncoding);				
				return (returnString);
			}//if
			if (data is String) {								
				returnString += String(data); //Hopefully it's correctly formatted!
				return (returnString);
			}//if
			if (data is Object) {
				//For all other occassions...
				for (item in data) {
					returnString += GETDataPrefix(tempURL) + encodeURIComponent(item) + "=" + encodeURIComponent(data[item]);
					tempURL += returnString;
				}//for
				return (returnString);
			}//if
			return (returnString);
		}//appendGETData
		
		/**
		 * Returns the appropriate variable prefix (? or &) to the supplied targetURL.
		 * 
		 * @param	targetURL The target URL to which the GET data will be appended.
		 * 
		 * @return Returns either "?" or "&" to be used to prefix URL variables in GET data.
		 */
		private static function GETDataPrefix(targetURL:String):String {
			if (targetURL.indexOf("?") > -1) {
				return ("&");
			}//if
			return ("?");
		}//GETDataPrefix
		
		private static function appendPOSTData(request:URLRequest):String {
			var returnString:String = new String();
			returnString = "";
			if (request == null) {
				return (returnString);
			}//if	
			if (request.method != URLRequestMethod.POST) {
				return (returnString);
			}//if
			var tempURL:String = request.url;
			var data:*= request.data;
			if (data is URLVariables) {
				var vars:URLVariables = data as URLVariables;
				for (var item:* in vars) {
					returnString += GETDataPrefix(tempURL) + encodeURIComponent(item) + "=" + encodeURIComponent(vars[item]);
					tempURL += returnString;
				}//for
				if (returnString.length > 0) {
					returnString =  returnString;// + lineEnd;
				}//if
				returnString = returnString.split("?").join(""); //POST variables don't include beginning "?"
				return (returnString);
			}//if			
			if (data is ByteArray) {
				//Adobe doesn't support this, but we can -- unless there's a good reason not to?
				returnString += ByteArray(data).readMultiByte(0, charSetEncoding);
				if (returnString.length > 0) {
					returnString =  returnString;// + lineEnd;
				}//if
				return (returnString);
			}//if
			if (data is String) {								
				returnString += String(data); //Hopefully it's correctly formatted!
				if (returnString.length > 0) {
					returnString =  returnString;// + lineEnd;
				}//if
				return (returnString);
			}//if
			if (data is Object) {
				//For all other occassions...
				for (item in data) {
					returnString += GETDataPrefix(tempURL) + encodeURIComponent(item) + "=" + encodeURIComponent(data[item]);
					tempURL += returnString;
				}//for
				if (returnString.length > 0) {
					returnString = returnString;// + lineEnd;
				}//if
				returnString = returnString.split("?").join("");
				return (returnString);
			}//if		
			return (returnString);
		}//appendPOSTData
		
		private static function appendHeaderCookies(cookies:Vector.<HTTPCookie> = null):String {
			if (cookies == null) {
				return ("");
			}//if
			if (cookies.length<1) {
				return ("");
			}//if
			var returnStr:String = new String();
			for (var count:uint = 0; count < cookies.length; count++) {
				var currentCookie:HTTPCookie = cookies[count];				
				returnStr += HTTP_cookie_header + HTTPResponse.SPACE + currentCookie.name + HTTPCookie.nameValueDelimiter + currentCookie.value +lineEnd;				
			}//for			
			return (returnStr);
		}//appendHeaderCookies
				
	}//SOCKS5Model class

}//package