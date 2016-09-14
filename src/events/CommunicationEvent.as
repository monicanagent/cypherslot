/**
* 
* Defines events dispatched by implementations of the ICommunication interface.
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
		
	public class CommunicationEvent extends Event 
	{
		
		//Host connection established
		public static const CONNECT:String = "Event.CommunicationEvent.CONNECT";
		//Host response or asynchronous message received 
		public static const MESSAGE:String = "Event.CommunicationEvent.MESSAGE";
		//Host connection closed
		public static const CLOSED:String = "Event.CommunicationEvent.CLOSED";
		
		public function CommunicationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			
		}
		
	}

}