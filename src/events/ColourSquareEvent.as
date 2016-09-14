/**
* 
* Defines events dispatched by ColourSquare instances.
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
	public class ColourSquareEvent extends Event 
	{
		
		public static const SELECTED:String = "Event.ColourSquareEvent.SELECTED";
		
		public function ColourSquareEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new ColourSquareEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ColourSquareEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}