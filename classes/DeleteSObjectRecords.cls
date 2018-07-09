/*
	Delete recrods Dynamically. Call this class from deve console and provide Sobject api name in query and limit.
*/
global class DeleteSObjectRecords implements Database.Batchable<sObject> {
	
	String query;
	
	global DeleteSObjectRecords(String q) {
		query = q;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}