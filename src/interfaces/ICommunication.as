/**
* 
* Generic interface for communication library implementation.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package interfaces 
{
	import flash.events.IEventDispatcher;
	
	public interface ICommunication extends IEventDispatcher{
		
		function connect(onConnect:Function=null, timeout:Number=9000):void;
		function request(type:String, data:Object = null, onComplete:Function = null, timeout:Number=10000):void;
		function set gameInfo(infoSet:Object):void;
		function get gameInfo():Object;
		function disconnect():void;
		
	}
	
}