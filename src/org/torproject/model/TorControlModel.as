package org.torproject.model {
	
	/**
	 * Stores protocol lookup and other dynamic and static information for use with the Tor control socket connection.
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
	public class TorControlModel {
		
		/**
		 * Lookup table for various control messages, matched by "type" attribute.
		 */
		public static const TorControlTable:XML =
		<TorControlTable>
			<message type="authenticate">AUTHENTICATE</message>
			<message type="authenticate_password">AUTHENTICATE "%password%"</message>
			<message type="shutdown">SIGNAL SHUTDOWN</message>
			<message type="newcircuit">SIGNAL NEWNYM</message>
			<message type="enableevent">SETEVENTS EXTENDED %event_list%</message>
		</TorControlTable>
		
		/**
		 * Lookup table for various control messageresponses, matched by "type" attribute and "status" or "errorstatus" node names.
		 */
		public static const TorResponseTable:XML =
		<TorResponseTable>
			<status type="250">OK</status>
			<status type="251">NOOP</status>
			<status type="650">Asynchronous event notification</status>
			<errorstatus type="451">Resource exhausted</errorstatus>
			<errorstatus type="500">Syntax error: protocol</errorstatus>
			<errorstatus type="510">Unrecognized command</errorstatus>
			<errorstatus type="511">Unimplemented command</errorstatus>
			<errorstatus type="512">Syntax error in command argument</errorstatus>
			<errorstatus type="513">Unrecognized command argument</errorstatus>
			<errorstatus type="514">Authentication required</errorstatus>
			<errorstatus type="515">Bad authentication</errorstatus>
			<errorstatus type="550">Unspecified Tor error</errorstatus>
			<errorstatus type="551">Internal error</errorstatus>
			<errorstatus type="552">Unrecognized target entity</errorstatus>
			<errorstatus type="553">Invalid configuration value</errorstatus>
			<errorstatus type="554">Invalid descriptor</errorstatus>
			<errorstatus type="555">Unmanaged entity</errorstatus>			
		</TorResponseTable>
		
		//Protocol constants
		public static const charSetEncoding:String = "iso-8859-1";
		public static const controlLineEnd:String = String.fromCharCode(13) + String.fromCharCode(10);
		public static const asynchEventStatusCode:int = 650; //Should be the same as in TorResponseTable data		
		
		/**
		 * Looks up a control message, as defined in the TorControlTable XML data, using a static mnemonic.
		 * 
		 * @param	msgType The type of message to look up (e.g. "authenticate")
		 * 
		 * @return The command string, as found in the TorControlTable XML data, or null if not found. Note that this data
		 * may include metadata fields so care should be taken when using retrieved control messages as-is.
		 */
		public static function getControlMessage(msgType:String):String {
			if ((msgType == "") || (msgType == null)) {
				return (null);
			}//if
			var compareMsgType:String = new String(msgType);
			compareMsgType = compareMsgType.toLowerCase();
			var messages:XMLList = TorControlTable.children();
			for (var count:uint = 0; count < messages.length(); count++) {
				var currentMessage:XML = messages[count] as XML;
				var currentMsgType:String = new String(currentMessage.@type);
				currentMsgType = currentMsgType.toLowerCase();
				if (currentMsgType == compareMsgType) {
					var messageStr:String = new String();
					messageStr = currentMessage.children()[0].toString();
					return (messageStr);
				}//if	
			}//for
			return (null);
		}//getControlMessage
		
		/**
		 * Looks up a control message response, as defined in the TorResponseTable XML data, using the response status code.
		 * 
		 * @param	msgType The status code of the message to look up (e.g. 250)
		 * 
		 * @return The static response string represented by the status code, or null if not found.
		 */
		public static function getControlResponse(status:int):String {
			if (status<0) {
				return (null);
			}//if		
			var messages:XMLList = TorResponseTable.child("status");
			for (var count:uint = 0; count < messages.length(); count++) {
				var currentMessage:XML = messages[count] as XML;
				var currentMsgStatusStr:String = new String(currentMessage.@type);
				var currentMsgStatus:int = int(currentMsgStatusStr);				
				if (status == currentMsgStatus) {
					var messageStr:String = new String();
					messageStr = currentMessage.children()[0].toString();
					return (messageStr);
				}//if			
			}//for
			return (null);
		}//getControlResponse		
		
		/**
		 * Determines whether the supplied status code is considered an error status code or a success status code.
		 * This is accomplished by comparing the status code against the TorResponseTable XML data. Statuses codes
		 * defined in <status> nodes are considered successful, while <errorstatus> nodes are considered errors.
		 * 
		 * @param	status The status code to analyze.
		 * @return True if the supplied code is considered to be an error code
		 */
		public static function isControlResponseError(status:int):Boolean {
			if (status<0) {
				return (false);
			}//if		
			var messages:XMLList = TorResponseTable.child("errorstatus");
			for (var count:uint = 0; count < messages.length(); count++) {
				var currentMessage:XML = messages[count] as XML;
				var currentMsgStatusStr:String = new String(currentMessage.@type);
				var currentMsgStatus:int = int(currentMsgStatusStr);				
				if (status == currentMsgStatus) {					
					return (true);
				}//if		
			}//for
			return (false);
		}//isControlResponseError	
		
	}//TorControlModel class

}//package