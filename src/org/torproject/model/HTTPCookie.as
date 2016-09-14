package org.torproject.model  {
	
	/**
	 * Stores HTTP 1.1 cookie information. Note that the corrent implementation does not support multiple cookies within a single "Set-Cookie" header
	 * (all data within such a header is currently treated as a single cookie).
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
	public class HTTPCookie {
		
		public static const cookieDelimiter:String = ";";	
		public static const nameValueDelimiter:String = "=";
		
		private var _name:String = null;
		private var _value:String = null;
		private var _expires:String = null;
		private var _domain:String = null;
		private var _path:String = null;
		private var _secure:Boolean = false;
		private var _httpOnly:Boolean = false;
		private var _isValid:Boolean = false;
		private var _rawData:String;
		
		/**
		 * Creates an instance of HTTPCookie by parsing the supplied cookie data into its components.
		 * 
		 * @param	rawCookieData An individual raw HTTP header cookie string to parse.
		 */
		public function HTTPCookie(rawCookieData:String) {
			this._rawData = rawCookieData;
			this.parseCookieData();
		}//constructor
		
		/**
		 * Parses the supplied raw cookie data into individual cookie components.
		 */
		private function parseCookieData():void {
			this._isValid = false;
			if (this._rawData == null) {
				return;
			}//if
			var cookieSplit:Array = this._rawData.split(cookieDelimiter);
			if (cookieSplit.length == 0) {
				return;
			}//if			
			for (var count:uint = 0; count < cookieSplit.length; count++) {
				try {
					var currentCookieItem:String = cookieSplit[count] as String;				
					var sepLocation:Number = currentCookieItem.indexOf(nameValueDelimiter);				
					if (sepLocation >= 0) {
						var cookiePre:String = currentCookieItem.substr(0, sepLocation);					
						var cookiePost:String = currentCookieItem.substr(sepLocation + 1);					
					} else {
						cookiePre = currentCookieItem;
						cookiePost = null;
					}//else				
					cookiePre = cookiePre.split(" ").join(""); //Remove spaces
					switch (cookiePre.toLowerCase()) {
						case "expires" :
							this._expires = cookiePost;
							break;
						case "domain" :
							this._domain = cookiePost;
							break;						
						case "path" :
							this._path = cookiePost;
							break;
						case "secure" :
							this._secure = true;
							break;		
						case "httponly" :
							this._httpOnly = true;
							break;					
						default:
							this._name = cookiePre;
							this._value = cookiePost;
							break;
					}//switch
				} catch (err:*) {					
				}//catch
			}//for		
			this._isValid = true;		
		}
		
		/**
		 * The cookie name as parsed from the supplied raw HTTP cookie header data.
		 */
		public function get name():String {
			return (this._name);
		}//get name
		
		/**
		 * The cookie value as parsed from the supplied raw HTTP cookie header data.
		 */
		public function get value():String {
			return (this._value);
		}//get value
		
		/**
		 * The cookie expiry date as parsed from the supplied raw HTTP cookie header data.
		 */
		public function get expires():String {
			return (this._expires);
		}//get expires
		
		/**
		 * The cookie domain information as parsed from the supplied raw HTTP cookie header data.
		 */
		public function get domain():String {
			return (this._domain);
		}//get domain
		
		/**
		 * The cookie path as parsed from the supplied raw HTTP cookie header data.
		 */
		public function get path():String {
			return (this._path);
		}//get path
		
		/**
		 * True if the supplied HTTP cookie information is flagged as secure (HTTPS), false otherwise.
		 */
		public function get secure():Boolean {
			return (this._secure);
		}//get secure
		
		/**
		 * True if the supplied HTTP cookie information is flagged as HTTP-only (non-HTTPS), false otherwise.
		 */
		public function get httpOnly():Boolean {
			return (this._httpOnly);
		}//get httpOnly
		
		/**
		 * True if the supplied HTTP cookie information appears to be valid and could be parsed correctly, false otherwise.
		 */
		public function get isValid():Boolean {
			return (this._isValid);
		}//get isValid
		
	}//HTTPCookie class

}//package