/*
	Traihead: Platform Dveloper 2 Badge
	https://trailhead.salesforce.com/modules/apex_triggers/units/apex_triggers_bulk
*/
trigger ClosedOpportunityTrigger on Opportunity (after insert,after update) {

	List<Task> taskLst = new List<Task>();

	for(Opportunity opp : [Select Id, Name, StageName From Opportunity Where StageName = 'Closed Won' And Id In: trigger.new]){
		Task t = new Task();
		t.WhatId = opp.Id;
		t.subject = 'Follow Up Test Task';

		taskLst.add(t);
	}

	if(taskLst.size()>0){
		insert taskLst;
	}
}