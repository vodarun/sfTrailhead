global class LeadProcessor implements Database.Batchable<sObject> {
	
	String query;
	
	global LeadProcessor() {
		query = 'Select Id, Name, LeadSource From Lead';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Lead> scope) {
   		System.debug(scope[0].LeadSource);
   		List<lead> ld = new List<Lead>();
		for(Lead l : scope){
			l.LeadSource = 'Dreamforce';
			ld.add(l);
		}

		update ld;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}