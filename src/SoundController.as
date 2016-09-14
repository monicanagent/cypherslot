/**
* 
* Central audio loader and controller.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{

	import flash.media.Sound;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	public class SoundController 
	{
		
		private static var _sounds:Array = new Array();
		private static var _channels:Array = new Array();
		private static var _config:XML = null;
		private static var _currentLoadIndex:uint = 0;
		private static var _transform:SoundTransform;
		private static var _mixerTransform:SoundTransform;
		
		public static function initialize(config:XML):void {
			_config = config;
			_transform = new SoundTransform(1, 0);
			_mixerTransform = new SoundTransform(1, 0);
			loadSounds();
		}
		
		public static function set volume(volumeSet:Number):void {
			_mixerTransform.volume = volumeSet;
			SoundMixer.soundTransform = _mixerTransform;
		}
		
		public static function get volume():Number {
			return (_mixerTransform.volume);			
		}
		
		public static function playSound(id:String, start:Number=0, loops:Number=0):Boolean {
			if (_sounds[id] == undefined) {
				return (false);
			}
			var channel:SoundChannel = Sound(_sounds[id]).play(start, loops, _transform);
			_channels.push({id:id, channel:channel});
			return (true);
		}
		
		public static function stopSound(id:String):void {
			for (var count:uint = 0; count < _channels.length; count++) {
				if (_channels[count].id == id) {
					SoundChannel(_channels[count].channel).stop();
					_channels.splice(count, 1);
					return;
				}
			}
		}
		
		private static function loadSounds():void {
			_currentLoadIndex = 0;
			trace ("SoundController.loadSounds: " + _config.audio.children().length());
			loadSound();
		}
		
		private static function loadSound():void {			
			var soundDef:XML = _config.audio.children()[_currentLoadIndex] as XML;
			trace ("soundDef: " + soundDef);
			var soundID:String = String(soundDef.@id);
			trace ("SoundController.loadSound ("+soundID+"): " + soundDef.toString());
			var soundLoader:Sound = new Sound();			
			var request:URLRequest = new URLRequest(soundDef.toString());
			soundLoader.addEventListener(Event.COMPLETE, onLoadSound);
			soundLoader.load(request, null);
		}
		
		private static function onLoadSound(eventObj:Event):void {
			eventObj.target.removeEventListener(Event.COMPLETE, onLoadSound);			
			var soundDef:XML = _config.audio.children()[_currentLoadIndex] as XML;			
			var soundID:String = String(soundDef.@id);
			_sounds[soundID] = Sound(eventObj.target);
			trace ("SoundController.onLoadSound (" + soundID + "): " + soundDef.toString());
			_currentLoadIndex++;
			if (_currentLoadIndex < _config.audio.children().length()) {
				loadSound();
			}
			
		}
		
	}

}