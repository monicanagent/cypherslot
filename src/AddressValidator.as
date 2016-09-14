/**
* 
* Functions for validating various cryptocurrency addresses.
*
* (C)opyright 2016
*
* This source code is protected by copyright and distributed under license.
* Please see the root LICENSE file for terms and conditions.
*
*/
package 
{

	public class AddressValidator 
	{
		
		private static const hexChars:String = "0123456789abcdef"; //only include lower-case as input will be converted
		
		/**
		 * Returns a string denoting the type of address(es) detected in the input string, or null
		 * if no valid cryptocurrency address has been detected.
		 */
		public static function validateAddress(address:String):String {
			if (checkEthereumAddress(address)) {
				return ("ethereum");
			}
			return (null);
		}
		
		private static function checkBitcoinAddress(address:String):Boolean {			
			address = address.split(" ").join("");
			if ((address == null) || (address == "")) {
				return (false);
			}
			//1= P2PKH address
			//3= P2SH address
			if ((address.indexOf("1")!=0) && (address.indexOf("3")!=0)) {
				//does not fit bit pattern of standard Bitcoin address
				return (false);
			}
			//do base58 decoding, etc.
			//all tests passed
			return (true);
		}
		
		private static function checkEthereumAddress(address:String):Boolean {			
			address = address.split(" ").join("");
			if ((address == null) || (address == "")) {
				return (false);
			}
			if (address.split("0x").length < 2) {
				//something should always follow "0x"
				return (false);
			}
			var hexAddress:String = address.split("0x")[1] as String;
			if (hexAddress.length != 40) {
				//numeric part of address must be 40 characters long
				return (false);
			}
			hexAddress = hexAddress.toLowerCase();
			for (var count:int = 0; count < hexAddress.length; count++) {
				var currentChar:String = hexAddress.substr(count, 1);
				if (hexChars.indexOf(currentChar) < 0) {
					//non hexadecimal character encountered
					return (false);
				}
			}
			//all tests passed
			return (true);
		}
		
	}

}