@isTest
global class WarehouseCalloutServiceMock implements HttpCalloutMock{
    // implement http mock callout
    global HTTPResponse respond(HTTPRequest req) {
    	System.assertEquals('https://th-superbadge-apex.herokuapp.com/equipment', req.getEndpoint());
    	System.assertEquals('GET', req.getMethod());

    	// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody('[{"sku":"12345","replacement": true, "Name":"Test Prod NAme"}]');
		res.setStatusCode(200);
		return res;
    }
}