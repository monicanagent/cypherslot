/**
* 
* Native window used to display a cryptocurrency faucet.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.system.ApplicationDomain;
	import flash.events.Event;
	import events.FaucetWindowEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.display.StageScaleMode;
	import fl.controls.UIScrollBar;
	import fl.controls.ScrollBarDirection;
	import fl.controls.ScrollPolicy;
	import fl.events.ScrollEvent;
	/**
	 * ...
	 * @author Patrick Bay
	 */
	public class FaucetWindow extends NativeWindow 
	{
		
		private var _htmlLoader:HTMLLoader;
		private var _initialized:Boolean = false;
		private var _wfInfo:Object = null;
		private var vSb:UIScrollBar = new UIScrollBar();
		private var hSb:UIScrollBar = new UIScrollBar();
		private var padding:Number = 0;
		private var _claimAmount:Number =-1;
		
		public function FaucetWindow(initOptions:NativeWindowInitOptions, titleVal:String, widthVal:Number, heightVal:Number) 
		{
			super(initOptions);
			this.title = titleVal;
			this.width = widthVal;
			this.height = heightVal;
			super.activate();
			if (stage != null) {
				initialize(null);
			} else {
				this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
			}
			trace ("New FaucetWindow created");
		}
		
		/**
		 * Updates various wallet/faucet meta tags in _wfInfo data.
		 */
		private function updateWFInfoMetaTags():void {
			var walletAddress:String = _wfInfo.wallet.address;
			_wfInfo.faucet.loginURL = _wfInfo.faucet.loginURL.split("%address%").join(walletAddress);
			_wfInfo.faucet.loginScript = _wfInfo.faucet.loginScript.split("%address%").join(walletAddress);
			_wfInfo.faucet.confirmScript = _wfInfo.faucet.confirmScript.split("%address%").join(walletAddress);
		}
		
		public function onClaimAmount(cbObj:* = null):void {
			trace ("onClaimAmount: " + cbObj);
			var claimStr:String = new String(cbObj);
			claimStr = claimStr.split(" ").join("");
			this._claimAmount = new Number(cbObj);			
			var event:FaucetWindowEvent = new FaucetWindowEvent(FaucetWindowEvent.ON_CLAIM);
			event.claimAmount = this._claimAmount;
			event.wfData = this._wfInfo;
			this.dispatchEvent(event);
		}
		
		public function closeWindow(success:Boolean = true):void {
			if (success) {
				var event:FaucetWindowEvent = new FaucetWindowEvent(FaucetWindowEvent.COMPLETE);
				event.claimAmount = this._claimAmount;
				event.wfData = this._wfInfo;
				this.dispatchEvent(event);
			}			
			this.onWindowClosing(null);			
			this.close();
		}
		
		public function load(wfInfo:Object):void {
			_wfInfo = wfInfo;
			if (!_initialized) {
				return;
			}
			this.updateWFInfoMetaTags();
			var request:URLRequest = new URLRequest(wfInfo.faucet.loginURL);
			this._htmlLoader.addEventListener(Event.LOCATION_CHANGE, this.onLocationChanged);
			this._htmlLoader.addEventListener(Event.HTML_RENDER, onHTMLRendered);
			this._htmlLoader.addEventListener(Event.HTML_BOUNDS_CHANGE, this.onHTMLRendered);
			this._htmlLoader.runtimeApplicationDomain = ApplicationDomain.currentDomain;
			this._htmlLoader.load(request);	
			this.stage.addChild(this._htmlLoader);
			this.updateDimensions(null);
			trace ("Now loading: " + wfInfo.faucet.loginURL);
			//create new vertical scrollbar
			
			vSb.height = this._htmlLoader.height + padding;
			vSb.visible = false;
			vSb.setScrollProperties(this._htmlLoader.height, 0, this._htmlLoader.contentHeight - this._htmlLoader.height, this._htmlLoader.height-16);
			this.stage.addChild(vSb);
			//create new horizontal scrollbar
			hSb.direction = ScrollBarDirection.HORIZONTAL;
			
			hSb.width = this._htmlLoader.width + padding;
			hSb.visible = true;
			hSb.setScrollProperties(this._htmlLoader.width, 0, this._htmlLoader.contentWidth - this._htmlLoader.width, 50);
			this.stage.addChild(hSb);
			//setup listener for scrollbar handling
			vSb.addEventListener(ScrollEvent.SCROLL, scrollArticle);
			hSb.addEventListener(ScrollEvent.SCROLL, scrollArticle);
			this._htmlLoader.addEventListener(Event.SCROLL, this.onContentScroll);
		}		
		
		private function updateDimensions(eventObj:Event):void {
			this._htmlLoader.width = width-34;
			this._htmlLoader.height = height-56;
			this._htmlLoader.x = -(width / 2)+46;
			this._htmlLoader.y = -(height / 2)+56;
			vSb.move(this._htmlLoader.x + this._htmlLoader.width, this._htmlLoader.y);
			hSb.move(this._htmlLoader.x, this._htmlLoader.y+ this._htmlLoader.height);
			vSb.setSize(vSb.width, this.height-56)
			hSb.setSize(this.width-36, vSb.height);			
			this.updateScrollBarProps();
		}
				
		private function updateScrollBarProps():void {
			vSb.setScrollProperties(this._htmlLoader.height, 0, this._htmlLoader.contentHeight - this._htmlLoader.height, this._htmlLoader.height-16);
			hSb.setScrollProperties(this._htmlLoader.width, 0, this._htmlLoader.contentWidth - this._htmlLoader.width, 50);			
			vSb.setSize(vSb.width, this.height-56)
			hSb.setSize(this.width-36, vSb.height);	
			vSb.visible = true;
			hSb.visible = true;				
		}
		
		private function onHTMLRendered(eventObj:Event):void {			
			this.updateScrollBarProps();			
		}
		
		private function onContentScroll(eventObj:Event):void {			
			vSb.scrollPosition = this._htmlLoader.scrollV;
			hSb.scrollPosition = this._htmlLoader.scrollH;
		}
		
		private function onLocationChanged(eventObj:Event):void {	
			trace ("location changed: " + this._htmlLoader.location);
			if (this._htmlLoader.window.onload != null) {
				//location has changed but onload already set so it won't trigger
				this.processOnPageRender();
			} else {
				this._htmlLoader.window.onload = this.processOnPageRender;
			}
		}
		
		//http://ethereum-faucet.com/sign_in?wallet=+0x420a3f5d6984dcad8a7b51b4d2f75c56545d0cde
		private function processOnPageRender(... args):void {
			trace ("Page rendered: " + this._htmlLoader.location);			
			if (this._htmlLoader.location == _wfInfo.faucet.loginURL) {
				//this._htmlLoader.window.__JSIcallback = this.JSInjectCallback;
				this._htmlLoader.window.eval(_wfInfo.faucet.loginScript);
				
			}
			if (this._htmlLoader.location==_wfInfo.faucet.confirmURL) {
				trace ("Post-processing confirm page");
				this._htmlLoader.window.__JSIcallback = this.onClaimAmount;
				this._htmlLoader.window.eval(_wfInfo.faucet.confirmScript);
			}
			if (this._htmlLoader.location==_wfInfo.faucet.claimURL) {
				trace ("Post-processing claim page");
				this._htmlLoader.window.__JSIcallback = this.closeWindow;
				this._htmlLoader.window.eval(_wfInfo.faucet.claimScript);				
			}
		}


		private function scrollArticle(eventObj:ScrollEvent):void{
			if(eventObj.target.direction == ScrollBarDirection.VERTICAL) {
				this._htmlLoader.scrollV = eventObj.target.scrollPosition;
			} else {
				this._htmlLoader.scrollH = eventObj.target.scrollPosition;
			}
		}
		
		private function onWindowClosing(eventObj:Event):void {
			this.removeEventListener(Event.RESIZE, this.updateDimensions);
			this.removeEventListener(Event.CLOSING, this.onWindowClosing);
			this._htmlLoader.removeEventListener(Event.SCROLL, this.onContentScroll);
			this._htmlLoader.removeEventListener(Event.LOCATION_CHANGE, this.onLocationChanged);
			this._htmlLoader.removeEventListener(Event.HTML_RENDER, onHTMLRendered);
			this._htmlLoader.removeEventListener(Event.HTML_BOUNDS_CHANGE, this.onHTMLRendered);
			this.stage.removeChild(this._htmlLoader);
			this.stage.removeChild(hSb);
			this.stage.removeChild(vSb);
			this.dispatchEvent(new FaucetWindowEvent(FaucetWindowEvent.CLOSING));
		}
		
		public function initialize(eventObj:Event):void {
			trace ("FaucetWindow initialized");
			this._htmlLoader = new HTMLLoader();
			this._htmlLoader.useCache = false;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.addEventListener(Event.RESIZE, this.updateDimensions);
			this.addEventListener(Event.CLOSING, this.onWindowClosing);
			_initialized = true;
			if (_wfInfo != null) {
				this.load(_wfInfo);
			}
		}
				
	}

}