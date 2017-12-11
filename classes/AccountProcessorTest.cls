@isTest
public with sharing class AccountProcessorTest {
	public static testMethod void testMethod1() {
		Account a = new Account();
		a.Name = 'TestAccount1';
		insert a;

		Contact c = new Contact();
		c.FirstName = 'TestContactFirst';
		c.LastName = 'TestContactLast';
		c.AccountId = a.Id;
		insert c;

		List<Id> accIds = new List<Id>();
		accIds.add(a.Id);

		Test.startTest();
		AccountProcessor.countContacts(accIds);
		Test.stopTest();

		Account acc = [Select Id,Number_of_Contacts__c From Account Where Id =: a.Id ];
		System.assertEquals(1,acc.Number_of_Contacts__c, 'Count not matching.');
	}
}