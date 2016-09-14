/**
* 
* Creates and controls an individual reel along with child ReelIcon instances.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{	
	import com.greensock.easing.Back;	
	import com.greensock.easing.Strong;
	import flash.display.MovieClip;
	import flash.events.Event;
	import events.ReelEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import ui.ReelController;
	import ui.ReelIcon;
	import flash.filters.BlurFilter;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import com.greensock.TweenLite;	
	import SoundController;	
	
	public class Reel extends MovieClip
	{
		
		private var _controller:ReelController;		
		private var _icons:Vector.<ReelIcon> = new Vector.<ReelIcon>();
		private var _animateDelta:Number = 0;
		private var _animating:Boolean = false;
		private var _spinSpeed:Number = 0;
		private var _stopIconIndex:uint = 0; //top icon
		private var _stopTimer:Timer;
		private var _reelIndex:uint;		
		
		
		public function Reel(controller:ReelController) {	
			_controller = controller;
		}
		
		public function get controller():ReelController {
			return (this._controller);
		}
		
		public function build(id:uint):void {
			var reelDef:XML = this.getReelDef(id);
			if (reelDef == null) {
				return;
			}
			this._reelIndex = id;
			var symbolList:XMLList = reelDef.children();			
			var previousIcon:ReelIcon;
			for (var count:uint = 0; count < symbolList.length(); count++) {
				var currentSymbol:uint = uint(symbolList[count].toString());				
				var newIcon:ReelIcon = new ReelIcon(count, currentSymbol, this);
				newIcon.createBitmap(_controller.getIconSource(currentSymbol));
				_icons[count] = newIcon;
				this.addChild(newIcon);
			}
		
		}	
		
		public function startSpin(accelerate:Boolean = true, delay:Number=0, topSpeed:Number=500):void {	
			this._stopIconIndex = uint.MAX_VALUE;
			this._spinSpeed = topSpeed;
			this.removeEventListener(Event.ENTER_FRAME, this.animateSpin);
			this.removeEventListener(Event.ENTER_FRAME, this.animateStop);
			this.addEventListener(Event.ENTER_FRAME, this.animateSpin);
			TweenLite.killTweensOf(this);
			_animating = true;
			if (accelerate) {
				TweenLite.to(this, 0.5, {animateDelta:topSpeed, ease:Back.easeIn, useFrames:false, delay:delay, onStart:this.playStartSpinSound});
			} else {
				this.animateDelta = topSpeed;
			}			
		}
		
		public function playStartSpinSound():void {
			SoundController.playSound("spinStart", 0.3);
			this.playSpinSound();
		}
		
		public function playStopSpinSound():void {
			this.stopSpinSound();
			SoundController.playSound("spinStop",0.3);
		}
		
		public function playSpinSound():void {			
			SoundController.playSound("reelSpin",Math.random()*4000,99990);
		}
		
		public function stopSpinSound():void {
			SoundController.stopSound("reelSpin");
		}
		
		public function clearAllWinAnimations():void {
			ReelIcon.clearAllWinAnimations();
		}
		
		private function stopSpinDelay(eventObj:TimerEvent):void {			
			this._stopTimer.stop();
			this._stopTimer.removeEventListener(TimerEvent.TIMER, this.stopSpinDelay);
			this._stopTimer = null;
			this.stopSpin(this._stopIconIndex, false, 0);
		}
		
		public function stopSpin(topIconIndex:uint, immediate:Boolean = false, delay:Number=0):void {
			if ((delay > 0) && (immediate == false)) {								
				this._stopTimer = new Timer(delay, 0);
				this._stopTimer.addEventListener(TimerEvent.TIMER, this.stopSpinDelay);
				this._stopTimer.start();
				this._stopIconIndex = topIconIndex;		
				return;
			}
			this._stopIconIndex = topIconIndex;					
			if (immediate) {
				TweenLite.killTweensOf(this);
				this.animateDelta *= 0.25; //cut immediately to quarter speed				
				_icons[this._stopIconIndex].topAlignIcons();
				applyMotionBlur(this.animateDelta);			
				this.playStopSpinSound();
				TweenLite.to(this, 0.3, {animateDelta:0, ease:Strong.easeOut, useFrames:false, onComplete:returnToStopPosition});
			} else {
				//stopped in animateSpin function when position is hit
			}
		}
		
		public function returnToStopPosition():void {
			this.removeEventListener(Event.ENTER_FRAME, this.animateSpin);
			this.addEventListener(Event.ENTER_FRAME, this.animateStop);
		}
		
		public function get animating():Boolean {
			return (this._animating);
		}
		
		private function animateStop(eventObj:Event):void {			
			if (_icons[this._stopIconIndex].y > 0) {
				this.animateDelta -= 1;
				topIcon.moveIcon(this.animateDelta);
			}
			if (_icons[this._stopIconIndex].y <= 0){
				_icons[this._stopIconIndex].y = 0;
				applyMotionBlur(0);
				this.removeEventListener(Event.ENTER_FRAME, this.animateStop);
				_animating = false;
				this.dispatchEvent(new ReelEvent(ReelEvent.STOPPED));
			}
		}
				
		private function applyMotionBlur(delta:Number):void {			
			if (delta == 0) {
				this.filters = [];
				return;
			}
			var filtersArr:Array = this.filters;
			if (filtersArr[0] == undefined) {
				filtersArr.push(new BlurFilter(0, 0, 1));
			}
			BlurFilter(filtersArr[0]).blurY = Math.abs(delta);
			this.filters = filtersArr;
		}
		
		public function get animateDelta():Number {
			return (_animateDelta);
		}
		
		public function set animateDelta(deltaSet:Number):void {
			if (this._animateDelta != deltaSet) {
				this.applyMotionBlur(deltaSet);
			}
			this._animateDelta = deltaSet;
		}
		
		public function animateSpin(eventObj:Event):void {			
			if (this.animateDelta>0) {
				bottomIcon.moveIcon(this.animateDelta);			
			} else {
				topIcon.moveIcon(this.animateDelta);
			}
			if (this._stopIconIndex != uint.MAX_VALUE) {
				if ((this.topIcon.index == this._stopIconIndex) && (this._stopTimer==null) && (this.previousReelSpinning==false)) {
				//	this.removeEventListener(Event.ENTER_FRAME, this.animateSpin);
					this.animateDelta *= 0.25; //cut immediately to quarter speed					
					_icons[this._stopIconIndex].topAlignIcons();
					applyMotionBlur(this.animateDelta);
					this.playStopSpinSound();
					TweenLite.to(this, 0.3, {animateDelta:0, ease:Strong.easeOut, useFrames:false, onComplete:returnToStopPosition});
				}
			}
		}
		
		public function get previousReelSpinning():Boolean {
			if (this._reelIndex == 0) {
				return (false);
			}
			if (this._controller.reels[this._reelIndex - 1].animating) {
				return (true);
			}
			return (false);
		}
		
		public function get icons():Vector.<ReelIcon> {
			return (_icons);
		}		
		
		public function get bottomIcon():ReelIcon {
			var botIcon:ReelIcon = null;
			for (var count:uint = 0; count < _icons.length; count++) {
				var currentIcon:ReelIcon = _icons[count];
				if (((currentIcon.y + currentIcon.height) > 0) && (currentIcon.y < _controller.maskArea.height)) {
					if (botIcon == null) {
						botIcon = currentIcon;	
					}
					if (currentIcon.y > botIcon.y) {
						botIcon = currentIcon;
					}
				}
			}			
			return (botIcon);
		}
		
		public function get topIcon():ReelIcon {
			var tIcon:ReelIcon = null;
			for (var count:uint = 0; count < _icons.length; count++) {
				var currentIcon:ReelIcon = _icons[count];				
				if (((currentIcon.y+currentIcon.height) > 0) && (currentIcon.y < _controller.maskArea.height)) {
					if (tIcon == null) {
						tIcon = currentIcon;	
					}
					if (currentIcon.y < tIcon.y) {
						tIcon = currentIcon;
					}
				}
			}			
			return (tIcon);
		}
		
		public function get maskArea():MovieClip {
			return (this._controller.maskArea);
		}
		
		private function getReelDef(id:uint):XML {
			if (_controller == null) {
				return (null);
			}
			var reelDefs:XMLList = _controller.config.reels.children();
			for (var count:uint = 0; count < reelDefs.length(); count++) {
				var currentDef:XML = reelDefs[count] as XML;
				if (uint(currentDef.@id) == id) {
					return (currentDef);
				}
			}
			return (null);
		}
		
	}

}