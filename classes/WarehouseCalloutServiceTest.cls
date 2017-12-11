@isTest
private class WarehouseCalloutServiceTest {
  // implement your mock callout test here
   @isTest static void testCallout() {
		// Set mock callout class 
		Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());

		WarehouseCalloutService.runWarehouseEquipmentSync();

		Product2 prod = new Product2();
                prod.Cost__c = 12.00;
                prod.Lifespan_Months__c = 2;
                prod.Maintenance_Cycle__c = 2;
                prod.Name = 'Test Prod NAme';
                prod.Current_Inventory__c = 12;
                
                prod.Warehouse_SKU__c = '12345';

                insert prod;
		// Verify response received contains fake values
		/*String contentType = res.getHeader('Content-Type');
		System.assert(contentType == 'application/json');*/
   }
}