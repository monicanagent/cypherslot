/**
* 
* Standard HTTP communications library.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import interfaces.ICommunication;
	import events.CommunicationEvent;	
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.events.Event;
	
	public class HTTPComm extends EventDispatcher implements ICommunication
	{
		
		private var _hostURL:String = null;
		private static var _msgIDCounter:Number = 0;
		private var _onConnect:Function = null;
		
		public function HTTPComm(hostURL:String) {
			this._hostURL = hostURL;
		}
		
		/* INTERFACE interfaces.ICommunication */
		
		public function connect(onConnect:Function = null):void {
			_onConnect = onConnect;
			this.sendPing();
		}
		
		public function request(type:String, data:Object=null, onComplete:Function=null):void {
			_msgIDCounter++;
			var request:URLRequest = new URLRequest(this._hostURL);
			request.method = URLRequestMethod.POST;
			var requestObj:Object = new Object;
			requestObj.request = type;
			requestObj.id = _msgIDCounter;
			requestObj.data = data;				
			request.data = JSON.stringify(requestObj);
			var loader:URLLoader = new URLLoader();
			if (onComplete!=null) {
				loader.addEventListener(Event.COMPLETE, onComplete);
			}
			loader.load(request);
		}		
		
		public function disconnect():void {
			
		}
		
		private function sendPing():void {
			this.request("ping", null, this.onPong);			
		}
		
		private function onPong(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, this.onPong);
			if (_onConnect != null) {
				_onConnect();
			}
			_onConnect = null;
		}
		
	}

}