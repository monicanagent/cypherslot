/**
* 
* Defines events dispatched by ReelController instances.
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
	

	public class ReelControllerEvent extends Event 
	{
		
		//Config and all icons loaded
		public static const INITIALIZED:String = "Event.ReelControllerEvent.INITIALIZED"; 
		//All reels have fully completed their spin/stop animations
		public static const REELS_STOPPED:String = "Event.ReelControllerEvent.REELS_STOPPED";
		
		public function ReelControllerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			
		}
		
	}

}