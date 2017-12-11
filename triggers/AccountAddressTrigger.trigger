/*
	Traihead: Platform Dveloper 2 Badge
	https://trailhead.salesforce.com/modules/apex_triggers/units/apex_triggers_intro
*/
trigger AccountAddressTrigger on Account (before insert,before update) {

	for(Account acc : trigger.new){
		if(acc.Match_Billing_Address__c == true && acc.BillingPostalCode!=Null){
			acc.ShippingPostalCode = acc.BillingPostalCode;
		}
	}
}