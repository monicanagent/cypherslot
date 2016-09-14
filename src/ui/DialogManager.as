/**
* 
* Manages the creation, display, and updates of various dialogs through the LayoutController.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{	
	import flash.display.DisplayObject;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import ui.LayoutController;
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	public class DialogManager 
	{
		
		private static var _dialogs:Vector.<XML> = new Vector.<XML>();
		private static var _dynamicElements:Vector.<DisplayObject> = new Vector.<DisplayObject>();		
		
		public static function registerDialog(definition:XML):void {
			_dialogs.push(definition);
			hide(definition, true);
		}		
		
		public static function hide(dialog:*, immediate:Boolean=false):void {
			var dialogID:String = null;
			if (dialog is XML) {
				dialogID = String(dialog.@id);
			}
			if (dialog is String) {
				dialogID = dialog;
			}
			while (_dynamicElements.length > 0) {
				var element:DisplayObject = _dynamicElements.pop();
				element.parent.removeChild(element);
			}
			if (immediate) {
				LayoutController.element(dialogID).alpha = 0;
				LayoutController.element(dialogID).visible = false;
			} else {
				TweenLite.to(LayoutController.element(dialogID), 0.5, {alpha:0, ease:Linear.easeOut, onComplete:onHideDialog, onCompleteParams:[dialogID]});
			}
		}
		
		public static function onHideDialog(dialogID:String):void {
			trace ("onHideDialog: " + dialogID);
			LayoutController.element(dialogID).visible = false;
		}
		
		public static function show(dialog:*, message:String, additionalElements:Array=null):void {
			var dialogID:String = null;
			if (dialog is XML) {
				dialogID = String(dialog.@id);
			}
			if (dialog is String) {
				dialogID = dialog;
			}
			while (_dynamicElements.length > 0) {
				var element:DisplayObject = _dynamicElements.pop();
				element.parent.removeChild(element);
			}
			var definition:XML = null;
			for (var count:int = 0; count < _dialogs.length; count++) {
				if (_dialogs[count].@id == dialogID) {
					definition = _dialogs[count];
					break;
				}
			}
			if (LayoutController.element(dialogID).visible==false) {
				LayoutController.element(dialogID).alpha = 0;
				LayoutController.element(dialogID).visible = true;
				if (additionalElements!=null) {
					for (count = 0; count < additionalElements.length; count++) {
						LayoutController.element(dialogID).parent.addChild(additionalElements[count]);
						_dynamicElements.push(additionalElements[count]);
					}
				}
				TweenLite.to(LayoutController.element(dialogID), 0.5, {alpha:1, ease:Linear.easeOut, onComplete:onShowDialog, onCompleteParams:[dialogID, message]});
			} else {
				if (additionalElements!=null) {
					for (count = 0; count < additionalElements.length; count++) {
						LayoutController.element(dialogID).parent.addChild(additionalElements[count]);
						_dynamicElements.push(additionalElements[count]);
					}
				}
				LayoutController.element(dialogID).alpha = 1;
				onShowDialog(dialogID, message);
			}
		}
		
		public static function onShowDialog(dialogID:String, message:String):void {	
			var dialog:DisplayObject = LayoutController.element(dialogID);
			var field:TextField = new TextField();
			var format:TextFormat = new TextFormat("_sans", 14, 0xFFFFFF);		
			field.type = "dynamic";
			field.selectable = false;
			field.multiline = true;
			field.wordWrap = true;
			_dynamicElements.push(field);
			dialog.parent.addChild(field);			
			field.x = 355;
			field.y = 260;
			field.width = 445;
			field.height = 250;			
			field.defaultTextFormat = format;			
			field.htmlText = message;			
		}
		
	}

}