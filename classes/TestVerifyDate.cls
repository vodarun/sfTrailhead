/*
	Traihead: Platform Dveloper 2 Badge
	https://trailhead.salesforce.com/modules/apex_testing/units/apex_testing_intro
*/
@isTest
private class TestVerifyDate {
	
	// date within range
	@isTest static void test_method_one() {
		Date d1 = Date.today();
		Date d2 = Date.Today().addDays(29);
		        
        Date resultDate = VerifyDate.CheckDates(d1,d2);
        System.assertEquals(d2,resultDate,'Dates as expected.');
	}
	
	@isTest static void test_method_two() {
		// Implement test code

		Date d1 = Date.today();
		Date d2 = Date.today().addDays(-1);

		Date resultDate = VerifyDate.CheckDates(d1,d2);
        System.assertnotEquals(d2,resultDate,'Dates as expected.');
	}
	
}