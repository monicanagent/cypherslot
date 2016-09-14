/**
* 
* Creates and controls a customizable horizontal, vertical, or diagonal progress bar.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.filters.DropShadowFilter;
	import flash.filters.BevelFilter;
	import com.greensock.TweenLite;
	import com.greensock.easing.Strong;	
	
	public class ProgressBar extends MovieClip 
	{
		
		public var barColour:uint = 0x10FF10;
		private var _background:MovieClip=null;
		private var _percentBar:MovieClip = null;
		private var _mask:MovieClip=null;
		private var _percent:Number = 100;
		private var _width:Number=600;
		private var _height:Number = 30;
		private var _cornerRadius:Number = 10;
		private var _lightAngle:Number =-45;
		
		public function ProgressBar() 
		{
			this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
			super();			
		}
		
		public function set percent(percentSet:Number):void {			
			if (percentSet == this._percent) {			
				return;
			}
			this._percent = percentSet;
			if (this._percent > 100) {
				this._percent = 100;
			}
			if (this._percent < 0) {
				this._percent = 0;
			}
			TweenLite.killTweensOf(this._percentBar);
			if (this._background.width > this._background.height) {	
				var targetSize:Number = this._background.width * (this._percent / 100);				
				this._percentBar.height = this._background.height;				
				TweenLite.to(this._percentBar, 1.5, {width: targetSize, ease:Strong.easeOut});
				this._percentBar.x = 0;
				this._percentBar.y = 0;
			} else if (this._background.width < this._background.height) {				
				this._percentBar.width = this._background.width;
				targetSize = this._background.height * (this._percent / 100);				
				TweenLite.to(this._percentBar, 1.5, {height: targetSize, y:(this._background.height-targetSize), ease:Strong.easeOut});
				this._percentBar.x = 0;				
			} else {
				targetSize = this._background.width * (this._percent / 100); //same for both width and height
				TweenLite.to(this._percentBar, 1.5, {width: targetSize, height: targetSize, y:(this._background.height-targetSize), ease:Strong.easeOut});
				this._percentBar.x = 0;
			}			
		}
		
		private function drawMask():void {
			if (this._mask != null) {
				this.mask = null;
				this.removeChild(this._mask);
			}
			this._mask = new MovieClip()
			this.addChild(this._mask);
			this._mask.graphics.lineStyle(0, 0x000000, 0);
			this._mask.graphics.beginFill(0xFF0000, 1);
			this._mask.graphics.drawRoundRect(0, 0, this._width, this._height, this._cornerRadius, this._cornerRadius);			
			this._mask.graphics.endFill();
			this.mask = this._mask;
		}
		
		public function get percent():Number {
			return (this._percent);
		}
		
		private function drawBackground():void {
			if (this._background != null) {
				this._background.filters = [];
				this.removeChild(this._background);
			}
			this._background = new MovieClip();
			this.addChild(this._background);
			this._background.graphics.lineStyle(0, 0x000000, 0);
			this._background.graphics.beginFill(0xF0F0F0, 1);
			this._background.graphics.drawRoundRect(0, 0, this._width, this._height, this._cornerRadius, this._cornerRadius);			
			this._background.graphics.endFill();			
			var dsFilter:DropShadowFilter = new DropShadowFilter(4, this._lightAngle, 0, 0.6, 8, 8, 1, 3, true);
			this._background.filters = [dsFilter];
		}
		
		override public function set width(widthSet:Number):void {
			this._width = widthSet;
			if (this._width < this._height) {
				this._cornerRadius = this._width / 2.01;
			} else {
				this._cornerRadius = this._height / 2.01;
			}
			this.drawBackground();
			this.drawMask();
			this.drawPercentBar();
		}
		
		override public function set height(heightSet:Number):void {
			this._height = heightSet;
			if (this._width < this._height) {
				this._cornerRadius = this._width / 2.01;
			} else {
				this._cornerRadius = this._height / 2.01;
			}
			this.drawBackground();
			this.drawMask();
			this.drawPercentBar();
		}
		
		override public function get width():Number {
			return (this._width);
		}
		
		override public function get height():Number {
			return (this._height);
		}
		
		private function drawPercentBar():void {
			if (this._percentBar != null) {
				this.removeChild(this._percentBar);
			}
			this._percentBar = new MovieClip()
			this.addChild(this._percentBar);
			this._percentBar.graphics.lineStyle(0, 0x000000, 0);
			this._percentBar.graphics.beginFill(this.barColour, 0.5);
			this._percentBar.graphics.drawRoundRect(0, 0, this._width, this._height, this._cornerRadius, this._cornerRadius);					
			this._percentBar.graphics.endFill();			
			var scalingRect:Rectangle = new Rectangle(this._cornerRadius, this._cornerRadius, this._percentBar.width - (this._cornerRadius*2), this._percentBar.height - (this._cornerRadius*2));			
			this._percentBar.scale9Grid = scalingRect;
			var bFilter:BevelFilter = new BevelFilter(8, this._lightAngle, 0xFFFFFF, 0.6, 0x000000, 0.6, 8, 8, 1, 3);
			this._percentBar.filters = [bFilter];
		}		
		
		private function initialize(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
			this.drawBackground();
			this.drawMask();
			this.drawPercentBar();		
		}		
		
	}

}