@isTest
private class LeadProcessorTest{
	@isTest
	static void itShould(){
		// Given
		List<lead> lds = new List<lead>();
		for(Integer i=1; i<201; i++){
			Lead l = new Lead();
			l.FirstName = 'Test_'+ i;
			l.LastName = 'LAst_'+i;
			l.Company = 'Company_'+i;
			l.Status = 'CLosed-Converted';
			l.LeadSource ='';
			lds.add(l);
		}

		insert lds;


		Test.startTest();
			LeadProcessor lp = new LeadProcessor();
			Id batchId = Database.executeBatch(lp);
		Test.stopTest();

		

	}
}