/**
* 
* Defines events dispatched by LayoutController instances.
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
	

	public class LayoutControllerEvent extends Event 
	{
		
		//Layout has been completely rendered and is ready for use
		public static const COMPLETE:String = "Event.LayoutControllerEvent.COMPLETE";
		
		public function LayoutControllerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new LayoutControllerEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("LayoutControllerEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}