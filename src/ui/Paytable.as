/**
* 
* Creates and controls the paytable for the slot game.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui {	
	
	import events.LayoutControllerEvent;
	import flash.display.Bitmap;	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.PerspectiveProjection;
	import com.greensock.TweenLite;
	import com.greensock.easing.Strong;
	import flash.events.MouseEvent;
	
	public class Paytable {
		
		private var _target:Loader;
		private var _originalX:Number;		
		
		public function Paytable(target:Loader) {
			this._target = target;
			this._originalX = this._target.x;
		}
		
		public function show():void {
			trace ("Paytable.show");
			TweenLite.killTweensOf(this._target);			
			TweenLite.to(this._target, 1, {x:this._originalX, ease:Strong.easeOut, onComplete:this.addMouseListener});
			
		}
		
		private function addMouseListener():void {
			this._target.stage.addEventListener(MouseEvent.CLICK, this.onMouseClick);
		}
		
		public function hide(immediate:Boolean = false):void {	
			trace ("Paytable.hide");
			TweenLite.killTweensOf(this._target);			
			if (!immediate) {
				TweenLite.to(this._target, 1, {x:this._target.stage.stageWidth, ease:Strong.easeIn});
			} else {
				this._target.x = this._target.stage.stageWidth;
			}
		}
		
		private function onMouseClick(eventObj:MouseEvent):void {
			this._target.stage.removeEventListener(MouseEvent.CLICK, this.onMouseClick);
			this.hide();
		}
		
	}

}