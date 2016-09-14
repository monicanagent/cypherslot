/**
* 
* Main application entry class.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package
{
	import flash.display.MovieClip;
	import flash.events.Event;	
	import SoundController;	
	import ui.LayoutController;
	import events.LayoutControllerEvent;
	import ui.Reel;
	import ui.ReelController;
	import events.ReelControllerEvent;	
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import ui.ColourSquare;
	import ui.ResultsSelector;	
	import GameController;
	import ui.WaterEffect;	
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	import flash.system.Security;
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;	
	import flash.desktop.NativeApplication;
	
	public class Main extends MovieClip 
	{
		
		public static const configPath:String = "./config.xml";
		private var _configLoader:URLLoader;		
		private var _window:FaucetWindow;
		private var _config:XML = null;
		private var _gameController:GameController = null;
		private var _gameContainer:MovieClip;
		private var _waterEffect:WaterEffect = null;
		private var _motionOffset:uint = 0;
		private var _soundEffectIndexes:Array = new Array();		
		
		public function Main() {
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, this.destroy);
			this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
		}
		
		private function initialize(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
			this._gameContainer = new MovieClip;
			this.addChild(this._gameContainer);
			this._gameContainer.alpha = 0;
			this._configLoader = new URLLoader();
			var request:URLRequest = new URLRequest(configPath);
			this._configLoader.addEventListener(Event.COMPLETE, this.onLoadConfig);
			this._configLoader.load(request);			
		}
			
		private function destroy(eventObj:Event):void {
			trace ("Application is about to exit...");
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, this.destroy);
			if (this._gameController!=null) {
				this._gameController.destroy();
				this._gameController = null;
			}
		}
		
		private function rebuildSFXIndexes():void {
			_soundEffectIndexes = new Array();
			for (var count:int = 0; count < 9; count++) {
				_soundEffectIndexes.push(count + 1);
			}
		}
		
		private function doRipple(eventObj:MouseEvent):void {
			if (MovieClip(LayoutController.element("reels")).hitTestPoint(eventObj.stageX, eventObj.stageY)) {
				_motionOffset++;
				if (_motionOffset > 1) {
					if (_soundEffectIndexes.length == 0) {
						this.rebuildSFXIndexes();
					}
					//ensure we don't repeat SFX too much
					var sfxIndex:int = Math.round(Math.random() * (_soundEffectIndexes.length-1));
					var splashNum:int = _soundEffectIndexes.splice(sfxIndex, 1)[0];					
					SoundController.playSound("splash"+String(splashNum), 0.3, 0);
					_motionOffset = 0;					
				}				
				this._waterEffect.drawRipple(eventObj.stageX-LayoutController.element("reels").maskArea.width/2, eventObj.stageY-LayoutController.element("reels").maskArea.height/2, 50, 1);
			}
		}
		
		private function onLoadConfig(eventObj:Event):void {
			trace ("ReelController.onLoadConfig");
			this._configLoader.removeEventListener(Event.COMPLETE, this.onLoadConfig);
			this._config = new XML(this._configLoader.data);
			SoundController.initialize(this._config);
			LayoutController.dispatcher.addEventListener(LayoutControllerEvent.COMPLETE, this.onInterfaceReady);
			LayoutController.generate(this._gameContainer, this._config);			
		}
		
		
		private function onInterfaceReady(eventObj:LayoutControllerEvent):void {
			trace ("Main.onInterfaceReady");
			LayoutController.dispatcher.removeEventListener(LayoutControllerEvent.COMPLETE, this.onInterfaceReady);
			_gameController = new GameController(this._config);			
			this._waterEffect = new WaterEffect(LayoutController.element("reels"), 30, 15, 15);	
			this.rebuildSFXIndexes();
			this.addEventListener(MouseEvent.MOUSE_MOVE, this.doRipple);
			setTimeout(this.onTimerTick, Math.random() * 4000, this);
			TweenLite.to(this._gameContainer, 1, {alpha:1, ease:Linear.easeOut});
		}
		
		private function onTimerTick(targetObj:Main):void {
			SoundController.playSound("drip", 0.3, 0);
			targetObj._waterEffect.drawRipple ((LayoutController.element("reels").maskArea.width / 2)-30, 20, Math.round((Math.random() * 40))+30, 1);
			setTimeout(this.onTimerTick, Math.random() * 4000, targetObj);
		}
		
	}
	
}