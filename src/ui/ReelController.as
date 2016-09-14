/**
* 
* Creates, controls, and optionally masks multiple instances of the Reel class.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{
	import events.ReelEvent;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.system.LoaderContext;
	import flash.display.LoaderInfo;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.net.URLRequest;
	import events.ReelControllerEvent;
	import flash.events.EventDispatcher;	
	import ui.LayoutController;
	
	public class ReelController extends MovieClip
	{
				
				
		private var _initialized:Boolean = false;
		private var _container:MovieClip;		
		private var _iconLoader:Loader;
		private var _currentLoadIndex:uint;
		private var _config:XML;
		private var _mask:MovieClip;
		private var _sourceIcons:Vector.<Bitmap> = new Vector.<Bitmap>();
		private var _reels:Vector.<Reel> = new Vector.<Reel>();
		private var _reelsSpinning:Boolean = false;		
		
		public function ReelController(config:XML) {			
			this._config = config;
			this.loadIcons();
		}
		
		public function initialize(displayWidth:Number, displayHeight:Number, backgroundImageDef:XML=null):void {
			trace ("ReelController.initialize");
			this.buildMask(displayWidth, displayHeight);
			if (backgroundImageDef != null) {
				this.loadBackgroundImage(backgroundImageDef);
			}
		}
		
		public function enableMask():void {
			trace ("enableMask");
			this.mask = this.maskArea;
		}
		
		public function disableMask():void {
			trace ("disableMask");
			this.maskArea.alpha = 0;
			this.mask = null;
		}
		
		private function loadBackgroundImage(backgroundNode:XML):void {
			trace ("ReelController.loadBackgroundImage: " + backgroundNode);
			var loader:Loader = new Loader();
			var url:String = backgroundNode.toString();			
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			var x:Number = 0;
			var y:Number = 0;			
			try {
				x = Number(backgroundNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(backgroundNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			this.addChild(loader);			
			loader.x = x;
			loader.y = y;
			loader.load(request, context);
		}
		
		public function buildReel(reelID:uint):Reel {			
			if (!_initialized) {
				return (null);
			}
			var newReel:Reel = new Reel(this);
			newReel.addEventListener(ReelEvent.STOPPED, this.onReelStop);
			newReel.build(reelID);
			_reels[reelID] = newReel;
			this.addChild(newReel);
			return (newReel);
		}
		
		private function onReelStop(eventObj:ReelEvent):void {
			for (var count:uint = 0; count < _reels.length; count++) {
				if (_reels[count].animating) {
					return;
				}
			}
			this.dispatchEvent(new ReelControllerEvent(ReelControllerEvent.REELS_STOPPED));
		}
		
		public function clearAllWinAnimations():void {
			ReelIcon.clearAllWinAnimations();
		}
		
		public function get reels():Vector.<Reel> {
			return (_reels);
		}
		
		public function get reelsSpinning():Boolean {
			return (this._reelsSpinning);
		}
		
		public function spinAllReels(accelerate:Boolean = true, reelDelay:Number = 0, topSpeed:Number=500):void {
			for (var count:uint = 0; count < _reels.length; count++) {
				this.spinReel(count, accelerate, reelDelay * count, topSpeed);
			}
			this._reelsSpinning = true;
		}
		
		public function stopAllReels(topIconIndexes:Array, immediate:Boolean = false, reelDelay:Number = 0):void {			
			for (var count:uint = 0; count < _reels.length; count++) {
				this.stopReel(count, topIconIndexes[count], immediate, (reelDelay*count));
			}
			this._reelsSpinning = false;
		}
		
		private function spinReel(reelID:uint, accelerate:Boolean = true, delay:Number = 0, topSpeed:Number = 500):void {
			_reels[reelID].startSpin(accelerate, delay, topSpeed);
		}
		
		private function stopReel(reelID:uint, topIconIndex:uint, immediate:Boolean = false, delay:Number = 0 ):void {
			_reels[reelID].stopSpin(topIconIndex, immediate, delay);
		}
				
		
		public function get config():XML {
			return (this._config);
		}
		
		/**
		 * @return The symbols+reels definition as a JSON-encoded string.
		 */
		public function get JSONdefinition():String {
			var outObj:Object = new Object();			
			outObj.symbols = new Array();
			for (var count:int = 0; count < this._config.icons.children().length(); count++) {
				var symbolObj:Object = new Object(); //use an object in case we want to store additional data in the future
				var def:XML = this.getIconDef(count);
				symbolObj.name = String(def.@name);
				outObj.symbols.push(symbolObj);
			}
			outObj.reels = new Array();
			for (count = 0; count < _reels.length; count++) {
				var currentReel:Reel = _reels[count];
				outObj.reels.push(new Array());
				for (var count2:int = 0; count2 < currentReel.icons.length; count2++) {					
					outObj.reels[count].push(currentReel.icons[count2].symbol);
				}				
			}
			return (JSON.stringify(outObj));
		}
		
		public function getIconSource(index:uint):BitmapData {
			if (index > _sourceIcons.length) {
				return (null);
			}
			return (_sourceIcons[index].bitmapData);
		}
		
		public function getIconName(symbol:uint):String {
			var iconSourceNode:XML = this.getIconDef(symbol);
			return (String(iconSourceNode.@name));
		}
		
		public function get maskArea():MovieClip {
			return (this._mask);
		}
		
		private function buildMask(mWidth:Number, mHeight:Number):void {
			this._mask = new MovieClip();
			this._mask.graphics.lineStyle(1, 0xFF0000, 0.5);
			this._mask.graphics.beginFill(0xFF0000, 0.5);	
			this._mask.graphics.lineTo(mWidth, 0);
			this._mask.graphics.lineTo(mWidth, mHeight);
			this._mask.graphics.lineTo(0, mHeight);
			this._mask.graphics.lineTo(0, 0);
			this._mask.graphics.endFill();
			this.addChild(this._mask);
			this.mask = this._mask;
		}
		
		private function getIconDef(symbol:uint):XML {
			var iconList:XMLList = this._config.icons.children();			
			for (var count:uint = 0; count < iconList.length(); count++) {
				var currentIconDef:XML = iconList[count] as XML;				
				if (uint(currentIconDef.@symbol) == symbol) {
					return (currentIconDef);
				}
			}
			return (null);
		}
		
		private function loadIcons():void {
			trace ("ReelController.loadIcons");
			_currentLoadIndex = 0;
			var currentPath:String = String(this.getIconDef(_currentLoadIndex));			
			this.loadIcon(currentPath);
		}
		
		private function loadIcon(path:String):void {
			trace ("ReelController.loadIcon: " + path);
			this._iconLoader = new Loader();
			this._iconLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onLoadIcon);
			var request:URLRequest = new URLRequest(path);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			this._iconLoader.load(request, context);
		}
		
		private function onLoadIcon(eventObj:Event):void {			
			this._iconLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.onLoadIcon);
			_sourceIcons[_currentLoadIndex] = new Bitmap(this._iconLoader.contentLoaderInfo.content["bitmapData"]);			
			_currentLoadIndex++;			
			var currentPath:String = String(this.getIconDef(_currentLoadIndex));
			if ((currentPath!=null) && (currentPath!="") && (currentPath!="null")) {
				this.loadIcon(currentPath);
			} else {
				_initialized = true;
				this.dispatchEvent(new ReelControllerEvent(ReelControllerEvent.INITIALIZED));
			}
		}
		
	}

}