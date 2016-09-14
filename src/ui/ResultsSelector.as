/**
* 
* Creates a scrolling pane for encrypted results selections.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package ui 
{
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.display.DisplayObjectContainer;
	import fl.containers.ScrollPane;
	import events.ColourSquareEvent;
	import com.greensock.TweenLite;
	import com.greensock.easing.Expo;
		
	public class ResultsSelector extends MovieClip 
	{
		
		private var _scrollPane:ScrollPane;
		private var _itemsContainer:MovieClip;
		private var _contentBackground:MovieClip;
		private var _items:Vector.<MovieClip> = new Vector.<MovieClip>();
		private var _horizontal:Boolean = false;
		private var _itemSpacing:Number = 10;
		public var originalX:Number=Number.MIN_VALUE;
		public var originalY:Number=Number.MIN_VALUE;
		private var _width:Number = 100;
		private var _height:Number = 100;
		private var _reelID:uint;
		private var _currentSelection:String = null;
		private static var _selectors:Vector.<ResultsSelector> = new Vector.<ResultsSelector>();
		
		public function ResultsSelector(reelID:uint, horizontal:Boolean = false, itemSpacing:Number = 10) {
			_reelID = reelID;
			_selectors[_reelID] = this;
			_horizontal = horizontal;
			_itemSpacing = itemSpacing;
			this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
			super();			
		}
		
		public static function getSelectorByID(reelID:uint):ResultsSelector {
			if (_selectors[reelID] == undefined) {
				return (null);
			}
			return (_selectors[reelID]);
		}
		
		public static function hideSelectors(speed:Number = 1, delay:Number = 0 ):void {
			for (var count:int = 0; count < _selectors.length; count++ ) {
				if (_selectors[count].originalX == Number.MIN_VALUE) {
					_selectors[count].originalX = _selectors[count].x;
				}
				if (_selectors[count].originalY == Number.MIN_VALUE) {
					_selectors[count].originalY = _selectors[count].y;
				}
				if (speed>0) {
					TweenLite.to(_selectors[count], speed, {x:_selectors[count].stage.stageWidth, delay:(delay * count), ease:Expo.easeIn});
				} else {
					_selectors[count].x = _selectors[count].stage.stageWidth;
				}
			}
		}
		
		public static function showSelectors(speed:Number = 1, delay:Number = 0 ):void {
			for (var count:int = 0; count < _selectors.length; count++ ) {				
				TweenLite.to(_selectors[count], speed, {x:_selectors[count].originalX, delay:(delay*count), ease:Expo.easeOut});
			}
		}
		
		public function get currentSelection():String {
			return (_currentSelection);
		}
		
		public static function clearAllSelectors():void {
			for (var count:uint = 0; count < _selectors.length; count++) {
				_selectors[count].clearResultItems();
			}
		}
		
		public function clearResultItems():void {
			for (var count:uint = 0; count < _items.length; count++) {
				try {
					_items[count].destroy();
				} catch (err:*) {
				}
				_items[count].addEventListener(ColourSquareEvent.SELECTED, this.onSelectItem);
				_itemsContainer.removeChild(_items[count]);
			}
			_items = new Vector.<MovieClip>();
			_currentSelection = null;
			this._contentBackground.height = 1;
			this._contentBackground.width = 1;
			this._scrollPane.update();
		}
		
		public function addResultItem(item:MovieClip):void {
			this.createScrollPane();
			_items.push(item);
			item.addEventListener(ColourSquareEvent.SELECTED, this.onSelectItem);
			this._itemsContainer.addChild(item);
			if (_items.length > 1) {
				if (this._horizontal) {
					item.x = _items[_items.length - 2].x+_items[_items.length - 2].width+_itemSpacing;
				} else {
					item.y = _items[_items.length - 2].y+_items[_items.length - 2].height+_itemSpacing;
				}
			} else {
				if (this._horizontal) {
					item.x = _itemSpacing;
				} else {
					item.y = _itemSpacing;
				}
			}
			this.alignItem(item);
		}
		
		public function autoSelect():void {
			var randomIndex:Number = Math.floor(Math.random() * _items.length);	
			_items[randomIndex].setSelection();			
			if (this._horizontal) {
				_scrollPane.horizontalScrollPosition = _items[randomIndex].x-4;
			} else {
				_scrollPane.verticalScrollPosition = _items[randomIndex].y-4;
			}
		}
		
		private function onSelectItem(eventObj:ColourSquareEvent):void {
			_currentSelection = ColourSquare(eventObj.target).rawValue;
			for (var count:uint = 0; count < _items.length; count++) {
				if (_items[count] != eventObj.target) {
					_items[count].clearSelection();
				}
			}
		}
		
		private function alignAllItems():void {
			for (var count:uint = 0; count < _items.length; count++) {
				this.alignItem(_items[count]);
			}
		}
		
		private function alignItem(item:MovieClip):void {
			if (this._horizontal) {
				item.y = (this.height / 2) - (item.height / 2) - 10; //need better way to determine if scrollbar is present
			} else {
				item.x = (this.width / 2) - (item.width / 2) - 10;
			}
			var contentDim:Number = 0;
			for (var count:uint = 0; count < _items.length; count++) {
				if (_horizontal) {
					contentDim += _items[count].width + _itemSpacing;
				} else {
					contentDim += _items[count].height + _itemSpacing;
				}
			}
			contentDim += _itemSpacing; //end spacing
			if (_horizontal) {
				this._contentBackground.width = contentDim;
				this._contentBackground.height = 1;
			} else {
				this._contentBackground.height = contentDim;
				this._contentBackground.width = 1;
			}
			this._scrollPane.update();
		}
		
		private function drawContentBackground():void {
			this._contentBackground = new MovieClip();
			this._contentBackground.graphics.moveTo(0, 0);
			this._contentBackground.graphics.lineStyle(0, 0x000000, 0);
			this._contentBackground.graphics.beginFill(0xFF0000, 0.5);
			this._contentBackground.graphics.lineTo(this.width,0);
			this._contentBackground.graphics.lineTo(this.width, this.height);
			this._contentBackground.graphics.lineTo(this.width, 0);
			this._contentBackground.graphics.lineTo(0, 0);
			this._contentBackground.graphics.endFill();
			this._itemsContainer.addChild(this._contentBackground);
		}
		
		override public function set width(widthSet:Number):void {
			this._width = widthSet;
			this.createScrollPane();
			this._scrollPane.setSize(this._width, this._height);
			this._scrollPane.update();
		}
		
		override public function get width():Number {
			return (this._width);
		}
		
		override public function set height(heightSet:Number):void {
			this._height = heightSet;
			this.createScrollPane();
			this._scrollPane.setSize(this._width, this._height);
			this._scrollPane.update();
		}
		
		override public function get height():Number {
			return (this._height);
		}
		
		private function createScrollPane():void {
			if (this._itemsContainer == null) {
				this._itemsContainer = new MovieClip();
			}
			if (this._scrollPane == null) {
				this._scrollPane = new ScrollPane();
				this.addChild(this._scrollPane);
				this._scrollPane.source = this._itemsContainer;
			}
			if (this._contentBackground == null) {
				this.drawContentBackground();
			}
		}
		
		private function initialize(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
			this.createScrollPane();
			
		}
		
	}

}