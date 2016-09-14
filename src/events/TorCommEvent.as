/**
* 
* Defines events dispatched by instances of the TorComm class.
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
		
	public class TorCommEvent extends Event 
	{
		
		public var data:*;
		
		public function TorCommEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);			
		}
				
		
		override public function get target():Object {
			return (this);
		}
			
		public function removeEventListener(... args):void {
			
		}
		
	}

}