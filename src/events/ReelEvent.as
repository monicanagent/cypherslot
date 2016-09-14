/**
* 
* Defines events dispatched by Reel class instances.
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
	
	/**
	 * ...
	 * @author Patrick Bay
	 */
	public class ReelEvent extends Event 
	{
		//All reel animation has completed
		public static const STOPPED:String = "Event.ReelEvent.STOPPED";
		
		public function ReelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			
		}
		
	}

}