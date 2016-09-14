/**********************************************************\
|                                                          |
| Base64.as                                                |
|                                                          |
| Base64 library for ActionScript 3.                       |
|                                                          |
| Code Authors: Ma Bingyao <mabingyao@gmail.com>           |
| LastModified: Feb 8, 2016                                |
|                                                          |
\**********************************************************/

/*
 * interfaces:
 * import org.xxtea.Base64;
 * import flash.utils.ByteArray;
 * var data:ByteArray = new ByteArray();
 * data.writeUTFBytes("Hello PHPRPC");
 * var b64:String = Base64.encode(data);
 * trace(b64);
 * trace(Base64.decode(b64));
 */
 
package org.xxtea {
	import com.hurlant.util.der.ByteString;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	public class Base64 {
		private static const encodeChars:Array = [
			'A','B','C','D','E','F','G','H',
			'I','J','K','L','M','N','O','P',
			'Q','R','S','T','U','V','W','X',
			'Y','Z','a','b','c','d','e','f',
			'g','h','i','j','k','l','m','n',
			'o','p','q','r','s','t','u','v',
			'w','x','y','z','0','1','2','3',
			'4','5','6','7','8','9','+','/'];

		private static const decodeChars:Array = [
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
			52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
			-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
			-1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
			41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1];
		
		public static function encode(data:ByteArray):String {
			var out:Array = [];
			var r:int = data.length % 3;
			var len:int = data.length - r;
			var i:int = 0;
			var c:int;
			while (i < len) {
				c = data[i++] << 16 | data[i++] << 8 | data[i++];
				out.push(encodeChars[c >> 18]);
				out.push(encodeChars[c >> 12 & 0x3f]);
				out.push(encodeChars[c >> 6  & 0x3f]);
				out.push(encodeChars[c & 0x3f]);
			}
			if (r == 1) {
				c = data[i++];
				out.push(encodeChars[c >> 2]);
				out.push(encodeChars[(c & 0x03) << 4]);
				out.push("==");
			}
			else if (r == 2) {
				c = data[i++] << 8 | data[i++];
				out.push(encodeChars[c >> 10]);
				out.push(encodeChars[c >> 4 & 0x3f]);
				out.push(encodeChars[(c & 0x0f) << 2]);
				out.push("=");
			}
			return out.join('');
		}

		public static function decode(str:String):ByteArray {
			var len:int = str.length;
			var out:ByteArray = new ByteArray();
			var i:int = 0;
			var b1:int, b2:int, b3:int, b4:int;
			
			while (i < len) {
				/* b1 */
				do {
					b1 = decodeChars[str.charCodeAt(i++) & 0xff];
				} while (i < len && b1 == -1);
				if (b1 == -1) {
					break;
				}
				/* b2 */
				do {
					b2 = decodeChars[str.charCodeAt(i++) & 0xff];
				} while (i < len && b2 == -1);
				if (b2 == -1) {
					break;
				}
				out.writeByte((b1 << 2) | ((b2 & 0x30) >> 4));
				/* b3 */
				do {
					b3 = str.charCodeAt(i++) & 0xff;
					if (b3 == 61) {
						return out;
					}
					b3 = decodeChars[b3];
				} while (i < len && b3 == -1);
				if (b3 == -1) {
					break;
				}
				out.writeByte(((b2 & 0x0f) << 4) | ((b3 & 0x3c) >> 2));
				/* b4 */
				do {
					b4 = str.charCodeAt(i++) & 0xff;
					if (b4 == 61) {
						return out;
					}
					b4 = decodeChars[b4];
				} while (i < len && b4 == -1);
				if (b4 == -1) {
					break;
				}
				out.writeByte(((b3 & 0x03) << 6) | b4);
			}
			return out;
		}
		
		public static function decodeToHex(str:String):String {
			var hexChars:String = "0123456789ABCDEF";
			var bytes:ByteArray = decode(str);
			var returnStr:String = new String();
			bytes.position = 0;
			for (var count:uint = 0; count < bytes.length; count++) {
				var currentByte:uint = bytes.readUnsignedByte();
				returnStr = returnStr + hexChars.substr((currentByte >>> 4) & 0xF, 1);
				returnStr = returnStr + hexChars.substr(currentByte & 0xF, 1);				
			}
			return (returnStr);
		}
		
		public static function encodeFromHex(str:String):String {
			var ba:ByteArray = new ByteArray();			
			//align to byte if necessary
			if (Math.floor(str.length / 2) != (str.length / 2)) {				
				str = "0" + str;
			}			
			for (var count:uint=0; count < str.length ; count+=2) {
				var nybble1:String = str.substr(count, 1);				
				var nybble2:String = str.substr((count+1), 1);					
				trace ("Writing: " + "0x" + nybble1+nybble2);
				ba.writeByte(int("0x"+nybble1+nybble2));				
			}			
			return (encode(ba));
		}
	}
}