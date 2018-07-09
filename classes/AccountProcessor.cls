public class AccountProcessor {
	
	@future
	public static void countContacts(List<Id> accIds){
		List<Account> accs = new List<Account>();

		for(Account acc : [Select Id,Name,Number_of_Contacts__c, (Select Id From Contacts) From Account where Id IN : accIds] ){
			acc.Number_of_Contacts__c = acc.Contacts.size();
			accs.add(acc);
		}

		update accs;
	}
}