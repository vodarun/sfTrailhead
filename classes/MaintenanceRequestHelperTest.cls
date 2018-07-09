@isTest
private class MaintenanceRequestHelperTest {

    @isTest static void test_method_one() {

        List<Case> caseList = new List<Case>();
        List<Case> secondList = new List<Case>();

        Account acc = new Account();
        acc.Name = 'test';
        insert acc;

        Contact contact = new Contact();
        contact.FirstName = 'test';
        contact.LastName = 'last';
        contact.Email = 'test@test.com';
        contact.AccountId = acc.Id;
        insert contact;

        Vehicle__c vehicle = new Vehicle__c();
        vehicle.Name = 'car';
        insert vehicle;

        Product2 product = new Product2();
        product.Name = 'test';
        product.isActive = true;
        product.Maintenance_Cycle__c = 2;
        product.Replacement_Part__c = true;
        insert product;

        for(Integer i=1;i<=1000;i++){
            Case maintenanceNew             = new Case();
            maintenanceNew.Subject          = 'Other';
            maintenanceNew.Vehicle__c       = vehicle.Id;
            maintenanceNew.Product__c       = product.Id;
            maintenanceNew.ContactId        = contact.Id;
            maintenanceNew.AccountId        = acc.Id;
            maintenanceNew.Type             = 'Other';
            maintenanceNew.Status           = 'New';
            maintenanceNew.Equipment__c     = product.Id;
            maintenanceNew.Date_Reported__c = Date.today();
            maintenanceNew.Date_Due__c      = Date.today();

            caseList.add(maintenanceNew);   
        }

        insert caseList;
        System.assertEquals(1000,caseList.size());

        for(Case cas:caseList){
            //update information
            cas.Type = 'Repair';
            cas.Status = 'Closed';
            secondList.add(cas);
        }

        update secondList;
        List<Case> createdCases = [Select Id from Case where Type = 'Routine Maintenance'];
        System.assertEquals(1000,createdCases.size());

    }   
}