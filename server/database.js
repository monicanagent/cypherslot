/**
 * MongoDB interface script for CypherSlot games.
 * 
 * (C)opyright 2016
 * 
 * This source code is protected by copyright and distributed under license. 
 * Please see the root LICENSE file for terms and conditions.
 *  
 */
var MongoClient = require('mongodb').MongoClient;
var ObjectId = require('mongodb').ObjectID;
var assert = require('assert');
const color=require ("./ANSIcolor.js").code;

/*
* If Node complains that mongodb module can't be found, try:
*
* cd node_modules
* sudo npm install mongodb
* sudo npm install -g mongodb
* sudo npm link mongodb
*/

var mgdbURL = 'mongodb://localhost:27017/test';
var mongodb;

MongoClient.connect(mgdbURL, function(err, db) {
  assert.equal(null, err);
  mongodb=db;
  console.log(color().green+"Connected to MongoDB at "+color().yellow+mgdbURL+color().reset);   
  if ((MongoClient["_onConnect"]!=null) && (MongoClient["_onConnect"]!=undefined)) {	  
	  MongoClient["_onConnect"].call(MongoClient["_onConnectContext"], mongodb);
  }
});

exports.onConnect=(func)=> {
	MongoClient["_onConnect"]=func;	
}

exports.find=(collection, searchObj, generator)=>{
	var returnArr=[];	
	var results=mongodb.collection(collection).find(searchObj);	
	results.each(function(err, result) {
      assert.equal(err, null);	  
      if (result != null) {
		  returnArr.push(result);
      } else {
		  if ((generator!=null) && (generator!=undefined)) {
			generator.next(returnArr);		  
		  }
	  }	  
   })   
};


/*
Update array element faucetTimes[0]:
	db.wallets.update({},{$set:{"faucetTimes.0":{_id:"578124666e5f5f60e26a5bb9", dateTime:ISODate()}}})
*/
exports.update=(collection, searchObj, updateObj, generator)=>{
	var returnArr=[];
	var dateObj=new Date();
	updateObj._modified=dateObj.toISOString();
	mongodb.collection(collection).updateOne(searchObj,{"$set":updateObj},
	function(err, result) {
		if ((generator!=null) && (generator!=undefined)) {
			generator.next(returnArr);		  
		}
	})
}; 

exports.insert=(collection, insertObj, generator)=>{
	var returnArr=[];
	var dateObj=new Date();
	insertObj._modified=dateObj.toISOString();
	mongodb.collection(collection).insertOne(insertObj,
	function(err, result) {
		if ((generator!=null) && (generator!=undefined)) {
			generator.next(returnArr);		  
		}
	})
}; 