/**
* 
* Creates and manages a colour square representing an encrypted selection value.
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
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.filters.DropShadowFilter;
	import events.ColourSquareEvent;
	import ui.Tooltip;
	
	public class ColourSquare extends MovieClip 
	{
		
		private var _cSquares:MovieClip;
		private var _background:MovieClip;
		private var _renderValue:String = null;
		private var _rawValue:String = null;
		private var _mouseOver:Boolean = false;
		
		public function ColourSquare(renderValue:String, rawValue:String) {
			_renderValue = renderValue;
			_rawValue = rawValue;
			this.padRenderValue();
			this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
			super();			
		}
		
		public function get rawValue():String {
			return (this._rawValue);
		}
		
		public function destroy():void {
			this.removeChild(_cSquares);
			this.removeChild(_background);
			this._renderValue = "";
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
		}
		
		public function clearSelection():void {
			this.scaleX = 1;
			this.scaleY = 1;
			if (this.filters[0] != undefined) {
				this.x += 5;
				this.y += 5;
			}
			this.filters = [];
			this.width = 40;
			this.height = 40;
		}
		
		public function setSelection():void {
			this.onSelect(null);
		}
		
		private function initialize(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
			this.drawBackground();
			this.drawValue();
			this.mouseEnabled = true;
			this.buttonMode = true;
			this.useHandCursor = true;
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove); //MOUSE_OVER and MOUSE_OUT have odd behaviour (seems like gaps between box graphics)
			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, this.onMouseMove);
			this.addEventListener(MouseEvent.CLICK, this.onSelect);
		}
		
		private function onSelect(eventObj:MouseEvent):void {
			this.width += 10;
			this.height += 10;
			this.x -= 5;
			this.y -= 5;
			var filtersArr:Array = this.filters;
			filtersArr.push(new GlowFilter(0xFFFFFF, 1, 3, 3, 500, 3));
			filtersArr.push(new DropShadowFilter(8,45,0x000000,0.5,8,8,1,3));
			this.filters = filtersArr;
			this.dispatchEvent(new ColourSquareEvent(ColourSquareEvent.SELECTED));
		}
		
		private function onMouseMove(eventObj:MouseEvent):void {
			//over this and inside containing scroll pane
			if (this.hitTestPoint(eventObj.stageX, eventObj.stageY) && this.parent.parent.hitTestPoint(eventObj.stageX, eventObj.stageY)) {
				if (!this._mouseOver) {
					this._mouseOver = true;
					Tooltip.show(this, "0x" + this._renderValue, eventObj);
				}
			} else {
				if (this._mouseOver) {
					this._mouseOver = false;
					Tooltip.hide();
				}
			}
		}
		
		private function padRenderValue():void {			
			this._renderValue = this._renderValue.split(" ").join("");
			this._renderValue = this._renderValue.split("0x").join("");
			for (var count:uint = this._renderValue.length; count < 32; count++) {
				this._renderValue = "0" + this._renderValue;
			}
		}
		
		//colour is RGBA (24 bits colour, 16 bits alpha)
		private function drawSquare (target:MovieClip, xPos:Number, yPos:Number, dims:Number, colour:uint):void {
			var colourValue:uint = colour >> 8;
			var alphaVal:uint = (colour & 0xFF);
			var alphaNum:Number = (alphaVal / 255);
			target.graphics.moveTo(xPos, yPos);
			target.graphics.lineStyle(0, 0x000000, 0);
			target.graphics.beginFill(colourValue, alphaNum);
			target.graphics.lineTo(xPos + dims, yPos);
			target.graphics.lineTo(xPos + dims, yPos + dims);
			target.graphics.lineTo(xPos, yPos + dims);
			target.graphics.lineTo(xPos, yPos);
			target.graphics.endFill();
		}
		
		private function drawBackground():void {
			this._background = new MovieClip();
			this.addChild(this._background);			
			var currentX:Number = 0;
			var currentY:Number = 0;
			var toggleBlack:Boolean = true;
			for (var count:Number = 0; count < 16; count++) {
				if (toggleBlack) {
					this.drawSquare(this._background, currentX, currentY, 10, 0xFFFFFFFF);
				} else {
					this.drawSquare(this._background, currentX, currentY, 10, 0x000000FF);
				}
				currentX += 10;
				toggleBlack = !toggleBlack;
				if (currentX > 30) {					
					currentX = 0;
					currentY += 10;
					toggleBlack = !toggleBlack;
				}				
			}
		}
		
		private function drawValue():void {
			this._cSquares = new MovieClip();
			this.addChild(this._cSquares);
			var currentX:Number = 0;
			var currentY:Number = 0;
			for (var count:uint = 0; (count < this._renderValue.length) && (count < 32); count += 8) {
				var currentValue:uint = uint("0x" + this._renderValue.substr(count, 8));
				this.drawSquare(this._cSquares, currentX, currentY, 20, currentValue);
				currentX += 20;
				if (currentX > 20) {
					currentX = 0;
					currentY += 20;
				}
			}
		}
		
		override public function toString():String {
			return ("0x" + this._renderValue);
		}
		
	}

}