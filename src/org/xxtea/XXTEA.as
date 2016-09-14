/**********************************************************\
|                                                          |
| XXTEA.as                                                 |
|                                                          |
| XXTEA encryption algorithm library for ActionScript 3.   |
|                                                          |
| Encryption Algorithm Authors:                            |
|      David J. Wheeler                                    |
|      Roger M. Needham                                    |
|                                                          |
| Code Authors: Ma Bingyao <mabingyao@gmail.com>           |
| LastModified: Feb 8, 2016                                |
|                                                          |
\**********************************************************/

package org.xxtea {
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class XXTEA {
		private static const delta:uint = uint(0x9E3779B9);
		
		private static function mx(sum:uint, y:uint, z:uint, p:uint, e:uint, k:Array):uint {
			return (z >>> 5 ^ y << 2) + (y >>> 3 ^ z << 4) ^ (sum ^ y) + (k[p & 3 ^ e] ^ z);
		}
		
		private static function toByteArray(data:Array, includeLength:Boolean):ByteArray {
			var length:uint = data.length;
			var n:uint = (length - 1) << 2;
			if (includeLength) {
				var m:uint = data[--length];
				if ((m < n - 3) || (m > n)) {
					return null;
				}
				n = m;
			}
			var result:ByteArray = new ByteArray();
			result.endian = Endian.LITTLE_ENDIAN;
			for (var i:uint = 0; i < length; i++) {
				result.writeUnsignedInt(data[i]);
			}
			if (includeLength) {
				result.length = n;
				return result;
			}
			else {
				return result;
			}
		}

		private static function toUintArray(data:ByteArray, includeLength:Boolean):Array {
			var length:uint = data.length;
			var n:uint = length >> 2;
			if (length % 4 > 0) {
				n++;
				data.length += (4 - (length % 4));
			}
			data.endian = Endian.LITTLE_ENDIAN;
			data.position = 0;
			var result:Array = [];
			for (var i:uint = 0; i < n; i++) {
				result[i] = data.readUnsignedInt();
			}
			if (includeLength) {
				result[n] = length;
			}
			data.length = length;
			return result;
		}

		private static function encryptUintArray(v:Array, k:Array):Array {
			var n:uint = v.length - 1;
			if (n < 1) return v;
			var z:uint = v[n];
			var y:uint;
			var e:uint;
			var p:uint;
			var q:uint = uint(6 + 52 / (n + 1));
			var sum:uint = 0;
			
			while (0 < q--) {
				sum += delta;
				e = sum >> 2 & 3;
				for (p = 0; p < n; p++) {
					y = v[p + 1];
					z = v[p] += mx(sum, y, z, p, e, k);
				}
				y = v[0];
				z = v[n] += mx(sum, y, z, p, e, k);
			}
			return v;
		}

		private static function decryptUintArray(v:Array, k:Array):Array {
			var n:uint = v.length - 1;
			if (n < 1) return v;
			var z:uint;
			var y:uint = v[0];
			var e:uint;
			var p:uint;
			var q:uint = uint(6 + 52 / (n + 1));
			var sum:uint = q * delta;
			while (sum != 0) {
				e = sum >> 2 & 3;
				for (p = n; p > 0; p--) {
					z = v[p - 1];
					y = v[p] -= mx(sum, y, z, p, e, k);
				}
				z = v[n];
				y = v[0] -= mx(sum, y, z, p, e, k);
				sum -= delta;
			}
			return v;
		}

		private static function encryptByteArray(data:ByteArray, key:ByteArray):ByteArray {
			if (data.length == 0) {
				return new ByteArray();
			}
			var v:Array = toUintArray(data, true);
			var k:Array = toUintArray(key, false);
			k.length = 4;
			return toByteArray(encryptUintArray(v, k), false);
		}
		
		private static function decryptByteArray(data:ByteArray, key:ByteArray):ByteArray {
			if (data.length == 0) {
				return new ByteArray();
			}
			var v:Array = toUintArray(data, false);
			var k:Array = toUintArray(key, false);
			k.length = 4;
			return toByteArray(decryptUintArray(v, k), true);
		}
		
		private static function toBytes(data:String):ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(data);
			return bytes;
		}

		public static function encrypt(data:*, key:*):ByteArray {
			if (data is String) data = toBytes(data);
			if (key is String) key = toBytes(key);
			if (data === undefined || data === null || data.length === 0) {
				return data;
			}
			return encryptByteArray(data, key);
		}
		
		public static function decrypt(data:*, key:*):ByteArray {
			if (data is String) data = Base64.decode(data);
			if (key is String) key = toBytes(key);
			if (data === undefined || data === null || data.length === 0) {
				return data;
			}
			return decryptByteArray(data, key);
		}
		
		public static function encryptToString(data:*, key:*):String {
			return Base64.encode(encrypt(data, key));
		}
		
		public static function decryptToString(data:*, key:*):String {
			var buf:ByteArray = decrypt(data, key);
			var len:uint = buf.length;
			buf.position = 0;
			return buf.readUTFBytes(len);
		}
	}
}