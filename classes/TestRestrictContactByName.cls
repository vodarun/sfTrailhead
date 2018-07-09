@isTest
private class TestRestrictContactByName {

	
	
	@isTest static void test_method_one() {
	   try{
	   		Contact c = new Contact();
			c.FirstName = 'firstName';
			c.LastName = 'INVALIDNAME';
	   		insert c;
	   	} catch(Exception e){
	   		System.assertEquals(e.getMessage().contains('INVALIDNAME'),true,'Error messages match.');
	   	}
	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}