/**
* 
* General layout controller used to build a user interface from a XML definition within a specific target display controller.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui {
	
	import com.greensock.events.LoaderEvent;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.PerspectiveProjection;
	import events.LayoutControllerEvent;
	import flash.events.Event;
	import events.ReelControllerEvent;
	import flash.display.Loader;
	import flash.system.LoaderContext;
	import flash.display.LoaderInfo;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.net.URLRequest;
	import flash.display.SimpleButton;
	import ui.DialogManager;
	import fl.controls.Button;
	import fl.controls.ButtonLabelPlacement;
	import fl.controls.CheckBox;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;

	public class LayoutController  {
		
		private static var _config:XML;
		private static var _target:MovieClip;
		private static var _currentNodeIndex:uint = 0;
		private static var _currentSubNode:XML;
		private static var _currentSubNodeIndex:uint = 0;
		private static var _elements:Array = new Array();
		private static var _dispatcher:EventDispatcher;
		
		public static function generate(target:MovieClip, config:XML):void {
			_target = target;
			_config = config;
			_currentNodeIndex = 0;
			generateNextNode();
		}
		
		public static function get layoutTarget():MovieClip {
			return (_target);
		}
		
		public static function get dispatcher():EventDispatcher {
			if (_dispatcher == null) {
				_dispatcher = new EventDispatcher(null);
			}
			return (_dispatcher);
		}
		
		public static function element(id:String):* {
			if (_elements[id] != undefined) {
				return (_elements[id]);
			} else {
				return (null);
			}
		}
		
		private static function generateNextNode():void {
			if (_currentNodeIndex >= _config.layout.children().length()) {
				_elements["stage"] = _target.stage; //add stage reference
				dispatcher.dispatchEvent(new LayoutControllerEvent(LayoutControllerEvent.COMPLETE));
				return;
			}			
			var currentNode:XML = _config.layout.children()[_currentNodeIndex] as XML;			
			trace ("LayoutController.generateNextNode: "+currentNode);
			switch (String(currentNode.localName()).toLowerCase()) {
				case "reels": generateReels(currentNode);
						break;
				case "resultselector": generateResultSelector(currentNode);
						break;
				case "progressbar": generateProgressBar(currentNode);
						break;
				case "image": generateImage(currentNode);
						break;
				case "button": generateButton(currentNode);
						break;
				case "text": generateText(currentNode);
						break;
				case "toggle": generateToggle(currentNode);
						break;
				case "dialog": generateDialog(currentNode);
						break;
				default: 
					_currentNodeIndex++;
					generateNextNode();
					break;
			}
		}
		
		private static function generateReels(reelsNode:XML):void {
			trace ("LayoutController.generateReels");
			_currentSubNode = reelsNode;
			var x:Number = 0;
			var y:Number = 0;
			var width:Number = 450;
			var height:Number = 450;			
			var mask:Boolean = true;
			try {
				x = Number(reelsNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(reelsNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			try {
				width = Number(reelsNode.@width);
				if (isNaN(width)) {
					width = 450;
				}
			} catch (err:*) {
				width = 450;
			}
			try {
				height = Number(reelsNode.@height);
				if (isNaN(height)) {
					height = 450;
				}
			} catch (err:*) {
				height = 450;
			}	
			try {
				switch (String(reelsNode.@mask).toLowerCase()) {
					case "on":
						mask = true;
						break;
					case "enabled":
						mask = true;
						break;
					case "true":
						mask = true;
						break;
					case "1":
						mask = true;
						break;
					case "off":
						mask = false;
						break;
					case "disabled":
						mask = false;
						break;
					case "false":
						mask = false;
						break;
					case "0":
						mask = false;
						break;
					default:
						mask = true;
						break;
				}
			} catch (err:*) {
				mask = true;
			}
			_elements["reels"] = new ReelController(_config);
			_elements["reels"].addEventListener(ReelControllerEvent.INITIALIZED, onGenerateReels);			
			var reelsContainer:MovieClip = new MovieClip();
			_target.addChild(reelsContainer);		
			reelsContainer.addChild(_elements["reels"]);
			//_target.addChild();
			reelsContainer.x = x;
			reelsContainer.y = y;
			if (_currentSubNode.children().length() > 0) {
				_elements["reels"].initialize(width, height, _currentSubNode.children()[0] as XML);
			} else {
				_elements["reels"].initialize(width, height);
			}
			if (mask) {
				_elements["reels"].enableMask();
			} else {
				_elements["reels"].disableMask();
			}
		}
		
		private static function onGenerateReels(eventObj:ReelControllerEvent):void {
			trace ("LayoutController.onGenerateReels");
			_elements["reels"].removeEventListener(ReelControllerEvent.INITIALIZED, onGenerateReels);
			var numReels:uint = uint(_config.reels.children().length());
			var hSpacing:Number = 0;
			var rotationX:Number = 0;
			var rotationY:Number = 0;
			var rotationZ:Number = 0;
			try {
				hSpacing = Number(_currentSubNode.@hspacing);
				if (isNaN(hSpacing)) {
					hSpacing = 0;
				}
			} catch (err:*) {
				hSpacing = 0;
			}
			try {
				rotationX = Number(_currentSubNode.@rotationX);
				if (isNaN(rotationX)) {
					rotationX = 0;
				}
			} catch (err:*) {
				rotationX = 0;
			}	
			try {
				rotationY = Number(_currentSubNode.@rotationY);
				if (isNaN(rotationY)) {
					rotationY = 0;
				}
			} catch (err:*) {
				rotationY = 0;
			}
			try {
				rotationZ = Number(_currentSubNode.@rotationZ);
				if (isNaN(rotationZ)) {
					rotationZ = 0;
				}
			} catch (err:*) {
				rotationZ = 0;
			}
			for (var count:uint = 0; count < numReels; count++) {
				_elements["reels"].buildReel(count);
				if (count > 0) {
					_elements["reels"].reels[count].x = _elements["reels"].reels[count - 1].x + _elements["reels"].reels[count - 1].width + hSpacing;					
				}
			}
			//set rotation point at center
			var pp:PerspectiveProjection = new PerspectiveProjection();	
			pp.fieldOfView = 60;
			pp.projectionCenter = new Point(_elements["reels"].maskArea.width / 2, _elements["reels"].maskArea.height / 2);
			_elements["reels"].x -= _elements["reels"].maskArea.width / 2;
			_elements["reels"].y -= _elements["reels"].maskArea.height / 2;
			_elements["reels"].parent.x += _elements["reels"].maskArea.width / 2;
			_elements["reels"].parent.y += _elements["reels"].maskArea.height / 2;
			_elements["reels"].parent.transform.perspectiveProjection = pp;
			_elements["reels"].parent.rotationX = rotationX;
			_elements["reels"].parent.rotationY = rotationY;
			_elements["reels"].parent.rotationZ = rotationZ;
			_currentNodeIndex++;
			generateNextNode();
		}		
		
		private static function generateImage(imageNode:XML):void {
			var loader:Loader = new Loader();
			var url:String = imageNode.toString();
			trace ("LayoutController.generateImage: " + url);
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			var x:Number = 0;
			var y:Number = 0;			
			try {
				x = Number(imageNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(imageNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onGenerateImage);			
			_elements[imageNode.@id] = loader;
			_target.addChild(loader);
			loader.x = x;
			loader.y = y;
			loader.load(request, context);
		}
		
		private static function onGenerateImage(eventObj:Event):void {
			trace ("LayoutController.onGenerateImage");
			eventObj.target.removeEventListener(Event.COMPLETE, onGenerateImage);
			_currentNodeIndex++;
			generateNextNode();
		}
		
		private static function generateDialog(dialogNode:XML):void {
			var loader:Loader = new Loader();
			var url:String = dialogNode.background.toString();
			trace ("LayoutController.generateDialog: " + url);
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			var x:Number = 0;
			var y:Number = 0;			
			try {
				x = Number(dialogNode.background.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(dialogNode.background.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onGenerateDialog);
			_elements[dialogNode.@id] = loader;
			DialogManager.registerDialog(dialogNode);			
			_target.addChild(loader);
			loader.x = x;
			loader.y = y;
			loader.load(request, context);
		}
		
		private static function onGenerateDialog(eventObj:Event):void {
			trace ("LayoutController.onGenerateDialog");
			eventObj.target.removeEventListener(Event.COMPLETE, onGenerateDialog);
			_currentNodeIndex++;
			generateNextNode();
		}
		
		private static function generateResultSelector(selectorNode:XML):void {
			trace ("LayoutController.generateResultSelector");
			var newSelector:ResultsSelector = new ResultsSelector(uint(selectorNode.@reel));
			_target.addChild(newSelector);
			newSelector.width = Number(selectorNode.@width);
			newSelector.height = Number(selectorNode.@height);
			newSelector.x = Number(selectorNode.@x);
			newSelector.y = Number(selectorNode.@y);
			_currentNodeIndex++;
			generateNextNode();
		}
		
		private static function generateProgressBar(progressbarNode:XML):void {
			trace ("LayoutController.generateResultSelector");
			var bar:ProgressBar = new ProgressBar();
			_target.addChild(bar);
			var x:Number = 0;
			var y:Number = 0;
			var width:Number = 100;
			var height:Number = 40;
			try {
				x = Number(progressbarNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(progressbarNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			
			try {
				width = Number(progressbarNode.@width);
				if (isNaN(width)) {
					width = 100;
				}
			} catch (err:*) {
				width = 100;
			}
			try {
				height = Number(progressbarNode.@height);
				if (isNaN(height)) {
					height = 40;
				}
			} catch (err:*) {
				height = 40;
			}
			_elements[progressbarNode.@id] = bar;
			bar.x = x;
			bar.y = y;
			bar.width = width;
			bar.height = height;
			bar.percent = 0;
			_currentNodeIndex++;
			generateNextNode();
		}
		
		private static function generateButton(buttonNode:XML):void {
			trace ("LayoutController.generateButton");
			var button:SimpleButton = new SimpleButton();
			_currentSubNode = buttonNode;
			_currentSubNodeIndex = 0;
			_target.addChild(button);
			var x:Number = 0;
			var y:Number = 0;			
			try {
				x = Number(buttonNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(buttonNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			_elements[buttonNode.@id] = button;
			button.x = x;
			button.y = y;
			button.useHandCursor = true;
			button.enabled = true;
			loadButtonElement();
		}
		
		private static function loadButtonElement():void {
			if (_currentSubNodeIndex >= _currentSubNode.children().length()) {
				_currentNodeIndex++;
				generateNextNode();
				return;
			}
			var currentButtonNode:XML = _currentSubNode.children()[_currentSubNodeIndex] as XML;
			trace ("LayoutController.loadButtonElement: " + currentButtonNode);
			var url:String = currentButtonNode.toString();
			if ((url == null) || (url.split(" ").join("") == "")) {
				trace ("   Empty path; skipping...");
				_currentSubNodeIndex++;
				loadButtonElement();
				return;
			}
			var request:URLRequest = new URLRequest(url);
			var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadButtonElement);				
			loader.load(request, context);
		}
		
		private static function onLoadButtonElement(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, onLoadButtonElement);
			var buttonState:Loader = LoaderInfo(eventObj.target).loader;
			var button:SimpleButton = SimpleButton(_elements[_currentSubNode.@id]);
			var currentButtonNode:XML = _currentSubNode.children()[_currentSubNodeIndex] as XML;
			switch (currentButtonNode.localName()) {
				case "up" : button.upState = buttonState;
							if (button.hitTestState == null) {
								button.hitTestState = buttonState;
							}
							break;
				case "over" : button.overState = buttonState;
							break;
				case "down" : button.downState = buttonState;
							break;
				case "hit" : button.hitTestState = buttonState;
							break;
				default : trace ("LayoutController.onLoadButtonElement: unrecognized state for loaded button element: "+currentButtonNode.localName());
							break;
			}
			_currentSubNodeIndex++;
			loadButtonElement();
		}
		
		
		private static function generateToggle(toggleNode:XML):void {
			trace ("LayoutController.generateToggle");
			var toggle:CheckBox = new CheckBox();
			toggle.label = toggleNode.toString();
			_target.addChild(toggle);			
			var x:Number = 0;
			var y:Number = 0;
			var width:Number = 100;
			var height:Number = 40;
			try {
				x = Number(toggleNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(toggleNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}
			
			try {
				width = Number(toggleNode.@width);
				if (isNaN(width)) {
					width = 100;
				}
			} catch (err:*) {
				width = 100;
			}
			try {
				height = Number(toggleNode.@height);
				if (isNaN(height)) {
					height = 40;
				}
			} catch (err:*) {
				height = 40;
			}
			_elements[toggleNode.@id] = toggle;
			toggle.x = x;
			toggle.y = y;
			toggle.width = width;
			toggle.height = height;
			_currentNodeIndex++;
			generateNextNode();
		}
		
		private static function generateText(textNode:XML):void {
			trace ("LayoutController.generateText");
			var field:TextField = new TextField();			
			_target.addChild(field);
			var x:Number = 0;
			var y:Number = 0;
			var width:Number = 100;
			var height:Number = 40;
			var colour:Number = 0x000000;
			var size:Number = 12;
			var font:String = "_sans";
			var type:String = TextFieldType.DYNAMIC;
			var align:String = "left";
			switch (String(textNode.@type).toLowerCase()) {
				case "input": type = TextFieldType.INPUT; break;
				default: type = TextFieldType.DYNAMIC; break;
			}
			if ((textNode.@font != null) && (textNode.@font != undefined)) {
				font = String(textNode.@font);
			}
			if ((textNode.@align != null) && (textNode.@align != undefined)) {
				align = String(textNode.@align);
			}
			try {
				colour = Number(textNode.@color);
				if (isNaN(colour)) {
					colour = 0x000000;
				}
			} catch (err:*) {
				colour = 0x000000;
			}
			try {
				x = Number(textNode.@x);
				if (isNaN(x)) {
					x = 0;
				}
			} catch (err:*) {
				x = 0;
			}
			try {
				y = Number(textNode.@y);
				if (isNaN(y)) {
					y = 0;
				}
			} catch (err:*) {
				y = 0;
			}			
			try {
				width = Number(textNode.@width);
				if (isNaN(width)) {
					width = 100;
				}
			} catch (err:*) {
				width = 100;
			}
			try {
				height = Number(textNode.@height);
				if (isNaN(height)) {
					height = 40;
				}
			} catch (err:*) {
				height = 40;
			}
			try {
				size = Number(textNode.@size);
				if (isNaN(size)) {
					size = 12;
				}
			} catch (err:*) {
				size = 12;
			}
			field.type = type;
			if (type == TextFieldType.DYNAMIC) {
				field.selectable = false;
			}
			var format:TextFormat = new TextFormat(font, size, colour);
			format.align = align;
			field.setTextFormat(format);
			field.text = String(textNode.toString());
			field.setTextFormat(format);
			field.defaultTextFormat=format;
			field.x = x;
			field.y = y;
			field.width = width;
			field.height = height;
			_elements[textNode.@id] = field;
			_currentNodeIndex++;
			generateNextNode();
		}		
		
	}
}