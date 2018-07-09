/*
	Traihead: Platform Dveloper 2 Badge
https://trailhead.salesforce.com/modules/apex_testing/units/apex_testing_data
*/

public class RandomContactFactory {
	
	public static List<Contact> generateRandomContacts(Integer noOfContacts, String lastName){
		List<Contact> returnConLst = new List<Contact>();

		for(Integer i=0; i < noOfContacts;i++){
			Contact c = new Contact();

			c.FirstName = 'FirstName_' +i;
			c.LastName = 'lastName';

			returnConLst.add(c);
		}

		return returnConLst;
	}
}