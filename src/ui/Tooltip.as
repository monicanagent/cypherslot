/**
* 
* Creates an informational, rollover tooltip for a target display object.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;

	public class Tooltip {
		
		private static var _currentInstance:MovieClip;
		public static var textColor:uint = 0x000000;
		public static var bevel:Number = 10;
		public static var outlineColour:uint = 0x000000;
		public static var fillColour:uint = 0xFFFFFF;
		
		public static function show(targetRef:DisplayObjectContainer, msg:String, sourceEvent:MouseEvent=null):void {
			hide(); //if one is currently visible, remove it
			drawTooltip(msg);
			targetRef.stage.addChild(_currentInstance);
			_currentInstance.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if (sourceEvent != null) {
				onMouseMove(sourceEvent);
			}
		}
		
		private static function drawTooltip(msg:String):void {
			_currentInstance = new MovieClip();
			var field:TextField = new TextField();
			field.type = TextFieldType.DYNAMIC;
			var format:TextFormat = new TextFormat("_sans", 10, textColor, true);
			field.text = msg;
			field.setTextFormat(format);
			field.selectable = false;
			field.width = field.textWidth + 30;
			field.x = 5;
			field.y = 4;
			_currentInstance.addChild(field);
			_currentInstance.graphics.lineStyle(2, outlineColour, 1);
			_currentInstance.graphics.beginFill(fillColour, 1);
			_currentInstance.graphics.drawRoundRect(0, 0, field.textWidth + 12, field.textHeight + 11, bevel, bevel);
			_currentInstance.cacheAsBitmap = true;
		}
		
		private static function onMouseMove(eventObj:MouseEvent):void {
			if (_currentInstance!=null) {
				//_currentInstance.x = eventObj.stageX + 5;
				_currentInstance.x = eventObj.stageX - _currentInstance.width - 5;
				_currentInstance.y = eventObj.stageY;// - 40;
				if (_currentInstance.y < 0) {
					_currentInstance.y = 0;
				}
				if (_currentInstance.x < 0) {
					_currentInstance.x = 0;
				}
				//Offsets aren't dynamic. Code below will make tooltip appear in more "traditional" upper-right position.
				/*
				if ((_currentInstance.x + _currentInstance.width) > (_currentInstance.stage.stageWidth-_currentInstance.width)) {
					_currentInstance.x = eventObj.stageX - _currentInstance.width;
				}
				if ((_currentInstance.y + _currentInstance.height) > _currentInstance.stage.stageHeight) {
					_currentInstance.y = _currentInstance.stage.stageHeight - _currentInstance.height;
				}
				*/
			}
		}
		
		public static function hide():void {
			if (_currentInstance != null) {
				try {
					_currentInstance.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
					_currentInstance.parent.removeChild(_currentInstance);
					_currentInstance = null;
				} catch (err:*) {
					
				}
			}
		}
		
	}

}