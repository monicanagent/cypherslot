package org.torproject.events {
	
	import flash.events.Event;
	import org.torproject.model.TorASError;
	
	/**
	 * Contains data and information from various events raised within a TorControl instance.
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
	public class TorControlEvent extends Event {
		
		/**
		 * Dispatched whenever Tor sends a STDOUT log message (included as both rawMessage and body properties). 
		 * The verbosity of log information is set in the config data for the Tor binary in TorControl.as
		 */
		public static const ONLOGMSG:String = "Event.TorControlEvent.ONLOGMSG";
		/**
		 * Dispatched once the Tor control connection is connected. Until authorized, the control connection should not be assumed to be usable.
		 */
		public static const ONCONNECT:String = "Event.TorControlEvent.ONCONNECT";
		/**
		 * Dispatched when the Tor control connection reports an error when connecting.
		 */
		public static const ONCONNECTERROR:String = "Event.TorControlEvent.ONCONNECTERROR";
		/**
		 * Dispatched once the Tor control connection is authenticated and ready to accept commands.
		 */
		public static const ONAUTHENTICATE:String = "Event.TorControlEvent.ONAUTHENTICATE";
		/**
		 * Dispatched whenever the Tor control connection replies with a synchronous response to a request. Asynchronous events (not requiring
		 * a request) that Tor may dispatch at any time are listed below.
		 */
		public static const ONRESPONSE:String = "Event.TorControlEvent.ONRESPONSE";		
		/**
		 * The following events refer to to: "TC: A Tor control protocol (Version 1) -- 4.1. Asynchronous events"
		 * https://gitweb.torproject.org/torspec.git?a=blob_plain;hb=HEAD;f=control-spec.txt
		 * 
		 * TO BE IMPLEMENTED IN NEXT FEW VERSIONS
		 */
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "DEBUG" event.
		 */
		public static const TOR_DEBUG:String = "Event.TorControlEvent.ONEVENT.TOR_DEBUG";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "INFO" event.
		 */
		public static const TOR_INFO:String = "Event.TorControlEvent.ONEVENT.TOR_INFO";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "NOTICE" event.
		 */
		public static const TOR_NOTICE:String = "Event.TorControlEvent.ONEVENT.TOR_NOTICE";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "WARN" event.
		 */
		public static const TOR_WARN:String = "Event.TorControlEvent.ONEVENT.TOR_WARN";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "ERR" event.
		 */
		public static const TOR_ERR:String = "Event.TorControlEvent.ONEVENT.TOR_ERR";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "CIRC" event.
		 */
		public static const TOR_CIRC:String = "Event.TorControlEvent.ONEVENT.TOR_CIRC";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "STREAM" event.
		 */
		public static const TOR_STREAM:String = "Event.TorControlEvent.ONEVENT.TOR_STREAM";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "ORCONN" event.
		 */
		public static const TOR_ORCONN:String = "Event.TorControlEvent.ONEVENT.TOR_ORCONN";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "BW" event.
		 */
		public static const TOR_BW:String = "Event.TorControlEvent.ONEVENT.TOR_BW";	
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "NEWDESC" event.
		 */
		public static const TOR_NEWDESC:String = "Event.TorControlEvent.ONEVENT.TOR_NEWDESC";	
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "ADDRMAP" event.
		 */
		public static const TOR_ADDRMAP:String = "Event.TorControlEvent.ONEVENT.TOR_ADDRMAP";	
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "AUTHDIR_NEWDESCS" event.
		 */
		public static const TOR_AUTHDIR_NEWDESCS:String = "Event.TorControlEvent.ONEVENT.TOR_AUTHDIR_NEWDESCS";
		/**
		 * Dispatched whenever the Tor control connection signals an asynchronous "DESCCHANGED" event.
		 */
		public static const TOR_DESCCHANGED:String = "Event.TorControlEvent.ONEVENT.TOR_DESCCHANGED";
		/**
		 * 4.1.10. Status events to be added once learn more about how they work.
		 */
		
		public var body:String = new String(); //Control event response body (parsed)
		public var status:int = 0; //Control event status code (parsed)
		public var rawMessage:String = new String(); //Control event response body (unparsed)
		public var torEvent:String = null; //Used only by Event.TorControlEvent.ONEVENT to specify asynchronous Tor event
		public var error:TorASError = null;
		
		public function TorControlEvent(p_type:String, p_bubbles:Boolean=false, p_cancelable:Boolean=false) {
			super(p_type, p_bubbles, p_cancelable);
		}//consructor
		
		/**
		 * Returns the Tor event shortcode for the provided long TorControlEvent event constant.
		 * For example, the constant TorControlEvent.TOR_DEBUG returns "DEBUG".
		 * 
		 * @param	torEvent A TorControlEvent event constant string.
		 * 
		 * @return The Tor shortcode that matches the supplied parameter, or null if no such code exists.
		 */
		public static function getTorEventShortcode(torEvent:String):String {
			//In the future, this may be safer to do as a lookup from within TorControlModel
			var eventSplit:Array = torEvent.split(".");
			var torEventString:String = eventSplit[eventSplit.length - 1] as String;
			var torEventSplit:Array = torEventString.split("_");
			var eventPrefix:String = torEventSplit[0] as String;
			if (eventPrefix != "TOR") {
				return (null);
			}//if
			var shortCode:String = torEventString.substr(4); //After "TOR_"
			return (shortCode);
		}//getTorEventShortcode
		
		/**
		 * Returns the Tor event longcode for the provided short Tor code. This is used to map Tor events to TorControlEvent
		 * constants.
		 * 
		 * For example, the Tor event "DEBUG" is mapped to the TorControlEvent.TOR_DEBUG constant string.
		 * 
		 * @param	torEvent A Tor shortcode event string.
		 * 
		 * @return A TorControlEvent constant event string, or null if no matching string exists.
		 */
		public static function getTorEventLongcode(torEvent:String):String {
			if ((torEvent == null) || (torEvent == "")) {
				return (null);
			}//if
			try {
				var longCodeString:String = "TOR_" + torEvent;				
				var longCode:String = TorControlEvent[longCodeString];				
				return (longCode);
			} catch (err:*) {
				return (null);
			}//catch
			return (null);
		}//getTorEventLongcode
		
		/**
		 * Checks if supplied TorControlEvent constant is an asynchronous Tor control connection event
		 * or a standard Flash event.
		 * 
		 * @param	torEvent A TorControlEvent event constant string.
		 * 
		 * @return True if the supplied event constant appears to be a Tor control connection event, false otherwise.
		 */
		public static function isTorEvent(torEvent:String):Boolean {
			//In the future, this may be safer to do as a lookup from within TorControlModel
			var eventSplit:Array = torEvent.split(".");
			var torEventString:String = eventSplit[eventSplit.length - 1] as String;
			var torEventSplit:Array = torEventString.split("_");
			var eventPrefix:String = torEventSplit[0] as String;
			if (eventPrefix == "TOR") {
				return (true);
			}//if
			return (false);
		}//isTorEvent
		
	}//TorControlEvent class

}//package