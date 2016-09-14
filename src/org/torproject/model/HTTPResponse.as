package org.torproject.model {
	
	import org.torproject.model.HTTPCookie;
	import org.torproject.model.HTTPResponseHeader;
	import flash.utils.ByteArray;
	
	/**
	 * Handles the parsing and conversion of a standard HTTP 1.1 response.
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
	public class HTTPResponse {
				
		public static const CR:String = String.fromCharCode(13);
		public static const LF:String = String.fromCharCode(10);
		public static const CRLF:String = CR+LF;
		public static const doubleCRLF:String = CRLF + CRLF;
		public static const SPACE:String = String.fromCharCode(32);	
		public static const cookieSetHeader:String = "set-Cookie";
		
		private var _statusCode:int = new int( -1);
		private var _status:String = new String();
		private var _headers:Vector.<HTTPResponseHeader> = null;
		private var _cookies:Vector.<HTTPCookie> = null;
		private var _body:String = new String();
		private var _rawResponse:ByteArray = null;
		private var _protocol:String = new String();
		private var _charSetEncoding:String = "iso-8859-1";
		
		public function HTTPResponse() {
			
		}		
		
		/**
		 * Parses the supplied data as HTTP response status information.
		 * 
		 * @param	rawResponseData The raw binary response data to attempt to parse.
		 * 
		 * @return True if the response status information was successfully parsed (subsequently available through the status and 
		 * HTTPVersion properties), false otherwise.
		 */
		public function parseResponseStatus(rawResponseData:ByteArray):Boolean {
			if (!this.statusSectionComplete(rawResponseData)) {
				return (false);
			}//if
			try {
				rawResponseData.position = 0;
				var responseString:String = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				var headerLines:Array = responseString.split(CRLF);
				var statusLine:String = headerLines[0] as String;
				var statusSplit:Array = statusLine.split(SPACE);
				var protocolHeader:String = statusSplit[0] as String;
				var statusCodeString:String = statusSplit[1] as String;				
				var statusString:String = statusSplit[2] as String;
				for (var count:uint = 3; count < statusSplit.length; count++) {
					statusString += SPACE+statusSplit[count] as String;
				}//for
				this._protocol = protocolHeader;
				this._statusCode = int(statusCodeString);
				this._status = statusString;				
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseResponseStatus
		
		/**
		 * Parses the supplied data as HTTP response headers.
		 * 
		 * @param	rawResponseData The raw binary response data to attempt to parse.
		 * 
		 * @return True if the response headers were successfully parsed (subsequently available through the headers property), false
		 * otherwise.
		 */
		public function parseResponseHeaders(rawResponseData:ByteArray):Boolean {
			if (!this.headerSectionComplete(rawResponseData)) {
				return (false);
			}//if
			try {
				rawResponseData.position = 0;
				this._headers = new Vector.<HTTPResponseHeader>();
				var responseString:String = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				var responseHeader:String = responseString.split(doubleCRLF)[0] as String;
				var headerLines:Array = responseHeader.split(CRLF);
				//Start at 1 since 0 is the status line
				for (var count:uint = 1; count < headerLines.length; count++) {
					var currentHeaderText:String = headerLines[count] as String;					
					var newHeader:HTTPResponseHeader = new HTTPResponseHeader(currentHeaderText);
					if (newHeader.name!="") {
						this._headers.push(newHeader);
					}//if
				}//for
				this.parseResponseCookies(); //Call ONLY after parsing headers since this is where cookies are stored
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseResponseHeaders
		
		private function parseResponseCookies():void {
			if (this.headers == null) {
				return;
			}//if
			if (this.headers.length<1) {
				return;
			}//if
			this._cookies = new Vector.<HTTPCookie>();
			for (var count:uint = 0; count < this.headers.length; count++) {
				var currentHeader:HTTPResponseHeader = this.headers[count];
				if (currentHeader.name.toLowerCase()==cookieSetHeader) {
					var newCookie:HTTPCookie = new HTTPCookie(currentHeader.value);
					if (newCookie.isValid) {
						this._cookies.push(newCookie);
					}//if
				}//if
			}//for
		}//parseResponseCookie
				
		
		/**
		 * Parses the supplied data as HTTP response body data.
		 * 
		 * @param	rawResponseData The raw binary response data to attempt to parse.
		 * 
		 * @return True if the response body was successfully parsed (subsequently available through the body property), false
		 * otherwise.
		 */
		public function parseResponseBody(rawResponseData:ByteArray):Boolean {
			//only when content-length omitted:
			//if (!this.bodySectionComplete(rawResponseData)) {
				//return (false);
			//}//if
			try {
				this._rawResponse = rawResponseData;
				rawResponseData.position = 0;
				this._body = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				var headerEndPos:int = this._body.indexOf(doubleCRLF) + 4;
				var bodyEndPos:int = this._body.lastIndexOf(doubleCRLF);
				var bodyLength:int = bodyEndPos - headerEndPos;	
				if (this.headerSectionComplete(this._rawResponse)) {
					var contentLengthHeader:int = -1;
					try { 						
						contentLengthHeader = int(this.getHeader("Content-Length", false).value);
					} catch (err:*) {
						contentLengthHeader = -1;
					}//catch
					if (contentLengthHeader > 0) {
						bodyEndPos = contentLengthHeader + headerEndPos;
					}//if				
				}//if
				this._body = this._body.substring(headerEndPos, bodyEndPos);				
				if (this.responseIsChunked) {					
					this._body = this.parseChunkedBody(this._body);
				}//if				
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseResponseBody
		
		
		/**
		 * True if the HTTP response body is marked as being chunked, false otherwise.
		 */
		public function get responseIsChunked():Boolean {
			try {
				var header:HTTPResponseHeader = this.getHeader("Transfer-Encoding", false);
				if (header == null) {
					return (false);
				}//if
				if (header.value.toLowerCase() == "chunked") {
					return (true);
				}//if			
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//get responseIsChunked
					
		/**
		 * Returns a parsed HTTP response header, as a HTTPResponseHeader instance.
		 * 
		 * @param	headerName The header name (for example, "Content-Length"), to attempt to retrieve.
		 * @param	caseSensitive True if the headerName parameter is to be matched exactly (case-sensitive), or not.
		 * 
		 * @return A HTTPResponseHeader instance with the matching header, or null of no such header can be found.
		 */
		public function getHeader(headerName:String, caseSensitive:Boolean=true):HTTPResponseHeader {
			if (this._headers == null) {
				return(null);
			}//if
			if (this._headers.length==0) {
				return(null);
			}//if
			for (var count:uint = 0; count < this._headers.length; count++) {
				var currentHeader:HTTPResponseHeader = this._headers[count];
				if (caseSensitive) {
					if (currentHeader.name == headerName) {
						return(currentHeader);
					}//if
				} else {
					if (currentHeader.name.toLowerCase() == headerName.toLowerCase()) {
						return(currentHeader);
					}//if
				}//else
			}//for
			return (null);
		}//getHeader
		
		public function set rawResponse(responseSet:ByteArray):void {
			this._rawResponse = responseSet;
		}
		
		public function get rawResponse():ByteArray {
			return (this._rawResponse);
		}
		
		private function parseChunkedBody(chunkedBody:String):String {			
			var assembledBody:String = new String();
			var workingCopy:String = new String(chunkedBody);
			var chunkSection:Object = this.getChunkSection(workingCopy);
			while (chunkSection.size > 0) {
				assembledBody += chunkSection.chunk;
				workingCopy = chunkSection.remainder;			
				chunkSection = this.getChunkSection(workingCopy);				
			}//while		
			return (assembledBody);
		}//parseChunkedBody
		
		private function getChunkSection(chunkedBody:String):Object {
			try {
				//Chunk length header may be variable length...
				var chunkLengthHeader:String = chunkedBody.substr(0, chunkedBody.indexOf(CR));
				chunkLengthHeader = chunkLengthHeader.split(LF)[0] as String; //Make sure to strip possible linefeed
				var chunkHeader:String = "0x" + chunkedBody.substr(0, Number(chunkLengthHeader.length)); //Make it hex				
				var chunkSize:Number = new Number(chunkHeader);								
				var chunkStart:int = chunkHeader.length;// + CRLF.length;
				var chunkEnd:int = chunkStart + chunkSize;			
				var returnData:Object = new Object();
				returnData.chunk = chunkedBody.substring(chunkStart, chunkEnd);
				returnData.chunk = returnData.chunk.substr(0, returnData.chunk.length);
				//returnData.chunk = returnData.chunk.substr(0, returnData.chunk.length);// + CRLF.length); //Remove linefeed after chunk section				
				returnData.size = chunkSize;
				returnData.original = chunkedBody;
				returnData.remainder = chunkedBody.substring(chunkEnd + CRLF.length);				
			} catch (err:*) {
				returnData = new Object();
				returnData.chunk = null;
				returnData.size = 0;
				returnData.original = chunkedBody;
				returnData.remainder = null;
			}//catch
			return (returnData);
		}//getChunkSection
		
		
		/**
		 * Checks if the supplied data appears to have sufficient information to parse the HTTP status.
		 * 
		 * @param	rawResponseData The raw response data to verify.
		 * 
		 * @return True if there is enough information to parse the HTTP status line, false otherwise.
		 */
		private function statusSectionComplete(rawResponseData:ByteArray):Boolean {
			try {
				rawResponseData.position = 0;
				var responseString:String = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				if (responseString.indexOf(CRLF) > -1) {
					return (true);
				} else {
					return (false);
				}//else
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//statusSectionComplete
		
		/**
		 * Checks if the supplied data appears to have sufficient information to parse HTTP headers.
		 * 
		 * @param	rawResponseData The raw response data to verify.
		 * 
		 * @return True if there seems to be enough information to parse HTTP headers, false otherwise.
		 */
		public function headerSectionComplete(rawResponseData:ByteArray):Boolean {
			try {
				rawResponseData.position = 0;
				var responseString:String = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				if (responseString.indexOf(doubleCRLF) > -1) {
					return (true);
				} else {
					return (false);
				}//else
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//headerSectionComplete
		
		/**
		 * Checks if the supplied data to have body information supplied.
		 * 
		 * @param	rawResponseData The raw response data to verify.
		 * 
		 * @return True if there seems to be enough information to parse HTTP headers, false otherwise.
		 */
		public function bodySectionComplete(rawResponseData:ByteArray):Boolean {
			try {
				rawResponseData.position = 0;
				var responseString:String = rawResponseData.readMultiByte(rawResponseData.length, this.charSet);
				var indexPos1:int = responseString.indexOf(doubleCRLF);				
				var indexPos2:int = responseString.lastIndexOf(doubleCRLF);				
				if (indexPos1 != indexPos2) {
					return (true);
				} else {
					return (false);
				}//else
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//bodySectionComplete
		
		public function get statusCode():int {
			return (this._statusCode);
		}
		
		public function get status():String {
			return (this._status);
		}
		
		public function get headers():Vector.<HTTPResponseHeader> {
			return (this._headers);
		}
		
		public function get cookies():Vector.<HTTPCookie> {
			return (this._cookies);
		}
		
		public function get body():String {
			return (this._body);
		}
		
		public function get protocol():String {
			return (this._protocol);
		}
		
		public function get charSet():String {
			return (this._charSetEncoding);
		}
		
		public function set charSet(setEncoding:String):void {
			this._charSetEncoding = setEncoding;
		}
		
	}

}