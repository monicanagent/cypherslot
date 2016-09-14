package org.torproject.model {
	
	/**
	 * Stores error information associated with various TorAS functionality.
	 * 
	 * @author Patrick Bay
	 */
	public class TorASError {
		
		public var status:int = -1;
		public var message:String = null;
		public var rawMessage:String = null;		
		
		public function TorASError(messageStr:String = "")	{
			this.message = messageStr;
		}
		
	}

}