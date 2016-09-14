/**
* 
* Manages the creation, positioning, and movement of an individual reel icon.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;	
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import com.greensock.TweenLite;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Strong;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import ui.Reel;
		
	public class ReelIcon extends MovieClip 
	{		
				
		private static var _animatingIcons:Vector.<ReelIcon> = new Vector.<ReelIcon>();
		
		private var _container:Bitmap;
		private var _index:uint;
		private var _symbol:uint;
		private var _reel:Reel;
		private var _originalX:Number;
		private var _originalY:Number;
		
		public function ReelIcon(index:uint, symbol:uint, parentReel:Reel) 	{
			_index = index;			
			_symbol = symbol;
			_reel = parentReel;			
			super();
			
		}
		
		public function createBitmap(source:BitmapData):void {
			var imageContainer:MovieClip = new MovieClip();
			this._container = new Bitmap(source);
			imageContainer.addChild(this._container);
			this.addChild(imageContainer);
			if (this.previousIcon != null) {
				this.y = this.previousIcon.y + this.previousIcon.height;
			}			
			//align for 3D transform
			var pp:PerspectiveProjection = new PerspectiveProjection();	
			var xAdjust:Number = this._container.width / 2;
			var yAdjust:Number = this._container.height / 2;
			this._container.x -= xAdjust;
			this._container.y -= yAdjust;			
			pp.projectionCenter = new Point(xAdjust, yAdjust);
			this._container.parent.transform.perspectiveProjection = pp;
			imageContainer.x += xAdjust;
			imageContainer.y += yAdjust;
		}
		
		public function moveIcon(delta:Number):void {			
			if (delta > 0) {				
				this.y += delta;
				if (this.y > this._reel.controller.maskArea.height) {
					this.y = this._reel.controller.maskArea.height;
				}				
				this.previousIcon.alignPrevious();
			} else {
				this.y += delta;
				if ((this.y + this.height) < 0) {
					this.y = 0-this.height;
				}
				this.nextIcon.alignNext();
			}
		}
		
		public function get index():uint {
			return (this._index);
		}
		
		public function get symbol():uint {
			return (this._symbol);
		}
		
		public static function clearAllWinAnimations():void {
			while (_animatingIcons.length > 0) {
				var currentIcon:ReelIcon = _animatingIcons.pop();
				currentIcon.clearWinAnimation();
			}
		}
		
		public function animateWin():void {
			_animatingIcons.push(this);	
			TweenLite.killTweensOf(this);
			this._originalX = this.x;
			this._originalY = this.y;
			this.animateWinIn();
		}
		
		public function animateWinIn():void {		
			TweenLite.to(this, 0.7, {width:this._container.width + 40, 
								height:this._container.height + 40, 
								x: this._originalX-20,
								y: this._originalY-20,
								ease:Bounce.easeOut, onComplete:this.animateWinOut});			
		}
		
		public function animateWinOut():void {	
			TweenLite.to(this, 0.3, {width:this._container.width, 
								height:this._container.height, 
								x: this._originalX,
								y: this._originalY,
								ease:Strong.easeIn, onComplete:this.animateWinIn});		
		}
		
		
		public function clearWinAnimation():void {
			TweenLite.killTweensOf(this);
			this.x = this._originalX;
			this.y = this._originalY;
			this.width = this._container.width;
			this.height = this._container.height;
		}
		
		private function alignPrevious():void {			
			this.y = this.nextIcon.y - this.height;			
			if (this.y <= 0) {
				return;
			} else {
				this.previousIcon.alignPrevious();
			}
		}
		
		/**
		 * Aligns next icon recursively until first off-area icon, then stop.
		 */
		private function alignNext():void {
			this.y = this.previousIcon.y+this.previousIcon.height;
			if (this.y >= this._reel.controller.maskArea.height) {
				return;
			} else {
				this.nextIcon.alignNext();
			}
		}
		
		public function topAlignIcons(topIcon:ReelIcon = null):void {
			if (topIcon == this) {
				return;
			}
			if (topIcon != null) {				
				//current icon follows top icon
				this.y = this.previousIcon.y + this.previousIcon.height;
				if (this.y > this._reel.controller.maskArea.height) {
					this.y = this._reel.controller.maskArea.height;
				}				
				this.nextIcon.topAlignIcons(topIcon);
			} else {
				this.y = 0;
				//current icon is top, following icons should align to it
				this.nextIcon.topAlignIcons(this);
			}
		}
		
		public function get previousIcon():ReelIcon {
			if (this._reel.icons.length == 0) {
				//first created icon
				return (null);
			}
			if ((this._index - 1) < 0) {
				return (this._reel.icons[this._reel.icons.length - 1]);
			} else {
				return (this._reel.icons[this._index-1]);
			}
		}
		
		public function get nextIcon():ReelIcon {
			if (this._reel.icons.length == 0) {
				//first created icon
				return (null);
			}			
			if ((this._index + 1) >= this._reel.icons.length) {				
				return (this._reel.icons[0]);
			} else {				
				return (this._reel.icons[this._index+1]);
			}
		}
	}

}