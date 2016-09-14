package org.torproject.model  {
	
	/**
	 * Stores information on one hop in a Tor circuit. This information is typically supplied by a TorControlCircuit instance.
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
	public class TorControlCircuitHop {
		
		public static const hopDataDelimiter:String = "=";
		public static const hopDataDelimiterAlt:String = "~";
		
		private var _rawHopData:String = null;
		private var _isValid:Boolean = false;
		private var _hopName:String = null;
		private var _hopAddress:String = null;
		
		public function TorControlCircuitHop(rawHopData:String) {
			if ((rawHopData != null) && (rawHopData != "")) {
				this._rawHopData = rawHopData;
				this.parseHopData();
			}//if
		}//constructor
		
		/**
		 * Returns the name portion of the supplied hop data.
		 */
		public function get name():String {
			return (this._hopName);
		}//get name
		
		/**
		 * Returns the address portion of the supplied hop data (a hashed token usually starting with "$").
		 */
		public function get address():String {
			return (this._hopAddress);
		}//get address
		
		/**
		 * Returns the raw hop data string supplied to this TorControlCircuitHop instance
		 */
		public function get rawHopData():String {
			return (this._rawHopData);
		}//get rawHopData
		
		/**
		 * Returns true if the supplied hop data was valid and could be parsed, false otherwise.
		 */
		public function get isValid():Boolean {
			return (this._isValid);
		}//get isValid
		
		private function parseHopData():void {
			try {				
				if (this._rawHopData.indexOf(hopDataDelimiter)>-1) {
					var hopSplit:Array = this._rawHopData.split(hopDataDelimiter);
				} else {
					hopSplit = this._rawHopData.split(hopDataDelimiterAlt);
				}//else
				this._hopAddress = new String(hopSplit[0] as String);
				this._hopName = new String(hopSplit[1] as String);
				this._isValid = true;
			} catch (err:*) {
				this._isValid = false;
			}//catch
		}//parseHopData
		
	}//TorControlCircuitHop class

}//package