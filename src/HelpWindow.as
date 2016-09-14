/**
* 
* Native help display window.
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
	public class HelpWindow extends NativeWindow 
	{
		
		private var _htmlLoader:HTMLLoader;
		private var _initialized:Boolean = false;
		private var _helpURL:String = null;
		private var vSb:UIScrollBar = new UIScrollBar();
		private var hSb:UIScrollBar = new UIScrollBar();
		private var padding:Number = 0;
		private static var _activeInstance:HelpWindow=null;
		
		public function HelpWindow(initOptions:NativeWindowInitOptions, helpURL:String, widthVal:Number, heightVal:Number) 
		{			
			super(initOptions);
			if (_activeInstance == null) {
				_activeInstance = this;
				this._helpURL = helpURL;
				this.width = widthVal;
				this.height = heightVal;
				super.activate();
				if (stage != null) {
					initialize(null);
				} else {
					this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
				}
				trace ("New HelpWindow created");
			} else {
				_activeInstance.activate();
				this.closeWindow();
			}
		}
		
		
		public function closeWindow(success:Boolean = true):void {	
			this.onWindowClosing(null);			
			this.close();
		}
		
		public function load(helpURL:String):void {
			_helpURL = helpURL;
			if (!_initialized) {
				return;
			}
			var request:URLRequest = new URLRequest(_helpURL);
			this._htmlLoader.addEventListener(Event.HTML_RENDER, onHTMLRendered);
			this._htmlLoader.addEventListener(Event.HTML_BOUNDS_CHANGE, this.onHTMLRendered);
			this._htmlLoader.runtimeApplicationDomain = ApplicationDomain.currentDomain;
			this._htmlLoader.load(request);	
			this.stage.addChild(this._htmlLoader);
			this.updateDimensions(null);
			trace ("Now loading: " +_helpURL);
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
			if ((this.title == null) || (this.title == "")) {
				trace ("Window title not specified on instantiation. Setting to document title \""+this._htmlLoader.window.document.title+"\"");
				this.title = this._htmlLoader.window.document.title;
			}
			this.updateScrollBarProps();			
		}
		
		private function onContentScroll(eventObj:Event):void {			
			vSb.scrollPosition = this._htmlLoader.scrollV;
			hSb.scrollPosition = this._htmlLoader.scrollH;
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
			if (this._htmlLoader!=null) {
				this._htmlLoader.removeEventListener(Event.SCROLL, this.onContentScroll);
				this._htmlLoader.removeEventListener(Event.HTML_RENDER, onHTMLRendered);
				this._htmlLoader.removeEventListener(Event.HTML_BOUNDS_CHANGE, this.onHTMLRendered);
				this.stage.removeChild(this._htmlLoader);			
				this.stage.removeChild(hSb);
				this.stage.removeChild(vSb);
				_activeInstance = null;
			}			
		}
		
		public function initialize(eventObj:Event):void {
			trace ("HelpWindow initialized");
			this._htmlLoader = new HTMLLoader();
			this._htmlLoader.useCache = false;
			this._htmlLoader.navigateInSystemBrowser = true;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.addEventListener(Event.RESIZE, this.updateDimensions);
			this.addEventListener(Event.CLOSING, this.onWindowClosing);
			_initialized = true;
			if (_helpURL != null) {
				this.load(_helpURL);
			}
		}
				
	}

}