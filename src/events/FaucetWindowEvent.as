/**
* 
* Defines events dispatched by FaucetWindow instances.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package events 
{
	import flash.events.Event;
	

	public class FaucetWindowEvent extends Event 
	{
		
		//An amount (prize) has been claimed from the faucet; claimAmount and wfData are included		
		public static const ON_CLAIM:String = "Event.FaucetWindowEvent.ON_CLAIM";
		//The faucet claim has been successfully completed; claimAmount and wfData are included
		public static const COMPLETE:String = "Event.FaucetWindowEvent.COMPLETE";
		//Faucet window is about to close
		public static const CLOSING:String = "Event.FaucetWindowEvent.CLOSING";
		
		public var claimAmount:Number = 0; //claimed amount
		public var wfData:Object = null; //associated wallet/faucet information object
		
		public function FaucetWindowEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new FaucetWindowEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("FaucetWindowEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}