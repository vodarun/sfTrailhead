public with sharing class DeepClonePlusController {

    public sObject parentObj {get;set;}
    public Map<string, Set<String>> relationshipMap = new Map<string, Set<String>>();// Custom metadataMap

    public List<sObjectChildRelationshipRow> myChildRelationshipRows {get;set;}
    public List<sObjectChildRelationship> myChildRelationships {get;set;}

    Map<String, Map<Id, sObject>> mapObjectQueries = new Map<String, Map<Id, sObject>>();
    Map<Integer, Map<String, List<sObject>>> mapObject = new Map<Integer, Map<String, List<sObject>>>();

    Map<Id, Id> mapIdOldNew = new Map<Id, Id>();
    public Map<String,String> objLabelMap {get;set;}
    Boolean isDefaultSelected;
    
    // Constructor
    public DeepClonePlusController(ApexPages.StandardController controller) {
        // Object labels
        objLabelMap = new Map<String,String>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        for(String s : schemaMap.keySet()){
            objLabelMap.put(schemaMap.get(s).getDescribe().getName(), schemaMap.get(s).getDescribe().getlabel());  
        }

        // set the default selected flag to true/false
        if(ApexPages.currentPage().getParameters().get('isDefaultSelect') <> null ){
            isDefaultSelected = Boolean.ValueOf( ApexPages.currentPage().getParameters().get('isDefaultSelect') );
        }else{
            isDefaultSelected = false;
        }

        //addFields method cannot be tested when passing data therefore we only run when test is not runnning (6/5/2017).
        if(!Test.isRunningTest()){controller.addFields(new List<String>{'Name'});}
        parentObj = controller.getRecord();

        myChildRelationshipRows = new List<sObjectChildRelationshipRow>();
        myChildRelationships = new List<sObjectChildRelationship>();

        // populate custom metadata settings
        getCustomMeatadaRealtions();
    }

    // Method called efrom VF Page action attribute
    public void initiateClone(){
        //** Build query to return the full object from an Id
        String originalObjectQuery = 'SELECT ID ';
        //** Call field set method to include fields required
        for(String s : readFieldSet('Deep_Clone',parentObj.Id.getSObjectType().getDescribe().getName()) ){
            originalObjectQuery += ' , '+ s ;
        }
        originalObjectQuery += ' FROM ' + parentObj.Id.getSObjectType().getDescribe().getName();
        originalObjectQuery += ' WHERE Id = \'' + parentObj.Id + '\'';
        //** Executive query to return the full object from an Id
        List<sObject> originalObject = Database.query(originalObjectQuery);
        System.debug('parent Record : ' +  originalObject);
        //** Execute clone()
        List<Id> clonedIds = prepCloneRecords(originalObject);
        //return clonedIds[0];
    }

    // Prepare records for cloning
    public List<Id> prepCloneRecords(List<sObject> originalObjects){
        
        //** Method variables        
        Map<String, List<Id>> mapObjectIds = new Map<String, List<Id>>();   
        Map<String, String> mapRelationshipFields = new Map<String, String>();                      
        //** Add Level 0 (originalObjects)
        Map<String, List<sObject>> mapObjectCurrent = new Map<String, List<sObject>>();
        
        //** Process input sObjects by sObjectType
        Set<String> origObjectTypeNames = new Set<String>();

        for (sObject originalObject : originalObjects) {
            if (!origObjectTypeNames.contains(originalObject.getSObjectType().getDescribe().getName())) {
                origObjectTypeNames.add(originalObject.getSObjectType().getDescribe().getName());
                System.debug(' Adding OBject  --' + origObjectTypeNames);
            }
        }

        System.debug(' origObjectTypeNames --' + origObjectTypeNames);

        for (String origObjectTypeName : origObjectTypeNames) {
            for (sObject originalObject : originalObjects) {
                if (origObjectTypeName == originalObject.getSObjectType().getDescribe().getName()) {
                    //** Add sObject to myChildRelationshipRows
                    myChildRelationshipRows.add(new sObjectChildRelationshipRow(originalObject,isDefaultSelected));
                    //** Populate Map<String, List<Id>> mapIdObjectTypeCurrent
                    if (mapObjectCurrent.containsKey(origObjectTypeName)) {
                        mapObjectCurrent.get(origObjectTypeName).add(originalObject);
                    } else {
                        mapObjectCurrent.put(origObjectTypeName, new List<sObject>{originalObject});
                    }
                }
            }
            //** Add myChildRelationshipRows to a myChildRelationships record with relationship information
            if (!myChildRelationshipRows.isEmpty()) {
                myChildRelationships.add(new sObjectChildRelationship(0, origObjectTypeName, null, myChildRelationshipRows));
            }
        }

        System.debug(' myChildRelationships --' + myChildRelationships);

        //** Populate Map<Integer, Map<String, List<Id>>> mapObject
        mapObject.put(0, mapObjectCurrent);
        System.debug(' mapObject --' + mapObject);
        //** Loop through levels 1-n (children)
        for (Integer currentLevel = 1 ; currentLevel < 20 ; currentLevel++) {
            mapObjectCurrent = new Map<String, List<sObject>>();
            System.debug(' mapObject.size() --' + mapObject.size());
            if(mapObject.size() == currentLevel){

                //** Loop through all tables
                for (String objType : mapObject.get(currentLevel-1).keySet()) {
                    System.debug(' objType --' + objType);
                    List<sObject> sObjectOriginals = mapObject.get(currentLevel-1).get(objType);
                     //** Get complete list of all child relationships for the given table 'objType'
                    List<Schema.ChildRelationship> childRelationships =
                        sObjectOriginals.get(0).getSObjectType().getDescribe().getChildRelationships();

                    //** Exit loop once there are no more childRelationships
                    if (!childRelationships.isEmpty()) {
                         //** Loop through all child relationships
                        for (Schema.ChildRelationship childRelationship : childRelationships) {

                            //** Only run script when the child relationships is acceptable (Custom Setting)
                            if( relationshipMap.get(objType) <> null && relationshipMap.get(objType).contains(childRelationship.getRelationshipName())){
                                System.debug(' childRelationship.getRelationshipName() --' + childRelationship.getRelationshipName());
                                
                                myChildRelationshipRows = new List<sObjectChildRelationshipRow>();
                                //** Name of the Child Table
                                String childObjectTypeName = childRelationship.getChildSObject().getDescribe().getName();
                                //** Name of the Child Field which stores the Parent sObject Id
                                String childObjectFieldName = childRelationship.getField().getDescribe().getName();
                                //** Build query to return all children in this relationship
                                String childRelationshipQuery = 'SELECT ID ';
                                //** Call field set method to include fields required
                                for(String s : readFieldSet('Deep_Clone',childObjectTypeName) ){
                                    childRelationshipQuery += ' , '+ s ;
                                }
                                
                                childRelationshipQuery += ' FROM ' + childObjectTypeName;
                                childRelationshipQuery += ' WHERE ' + childObjectFieldName;
                                childRelationshipQuery += ' IN (\'' + sObjectOriginals.get(0).Id + '\'';
                                for (Integer i = 1 ; i < sObjectOriginals.size() ; i++) {
                                    childRelationshipQuery += ', \'' + sObjectOriginals.get(i).Id + '\'';
                                }
                                childRelationshipQuery += ')';
                                System.debug(' childRelationshipQuery --' + childRelationshipQuery );
                                //** Executive query to return all children in this relationship
                                List<sObject> childRelationshipQueryResults = Database.query(childRelationshipQuery);
                                System.debug(' childRelationshipQueryResults --' + childRelationshipQueryResults );
                                //** Loop through all queried children
                                for (sObject childObject : childRelationshipQueryResults) {
                                    //** Add sObject to myChildRelationshipRows
                                    myChildRelationshipRows.add(new sObjectChildRelationshipRow(childObject,isDefaultSelected));
                                    //** Populate Map<String, List<Id>> mapIdObjectTypeCurrent
                                    if (mapObjectCurrent.containsKey(childObjectTypeName)) {
                                        mapObjectCurrent.get(childObjectTypeName).add(childObject);
                                    } else {
                                        mapObjectCurrent.put(childObjectTypeName, new List<sObject>{childObject});
                                    }
                                }

                                System.debug('mapObjectCurrent -- ' + mapObjectCurrent);
                                //** Add myChildRelationshipRows to a myChildRelationships record with relationship information
                                if (!myChildRelationshipRows.isEmpty()) {
                                    myChildRelationships.add(new sObjectChildRelationship(currentLevel,
                                        childObjectTypeName,
                                        childObjectFieldName,
                                        myChildRelationshipRows));
                                }

                            }

                        }
                    }
                }
            }
            //** Populate Map<Integer, Map<String, List<Id>>> mapObject
            if (! mapObjectCurrent.isEmpty()) {
                mapObject.put(currentLevel, mapObjectCurrent);
            }
        }

        //** Establish a list of Ids per each sObjectType for the result queries
        for (sObjectChildRelationship rel : myChildRelationships) {
            for (sObjectChildRelationshipRow row : rel.myChildRelationshipRowList) {
                if (!mapObjectIds.containsKey(rel.relationshipName)) {
                    mapObjectIds.put(rel.relationshipName, new List<Id>());
                }
                mapObjectIds.get(rel.relationshipName).add(row.sObjectOriginal.Id);
                if (!mapRelationshipFields.containsKey(rel.relationshipName)) {
                    mapRelationshipFields.put(rel.relationshipName, rel.relationshipFieldName);
                }
            }
        }

        //** Loop through each sObjectType to query the results for use later
        for (String objName : mapObjectIds.keySet()) {
            //** List of all Ids for the records to be cloned
            List<Id> sObjectIds = new List<Id>();
            sObjectIds = mapObjectIds.get(objName);
            //** List of all fields for the records to be cloned 
            List<String> sObjectFields = new List<String>();
            //** sObjectType
            Schema.SObjectType sObjectType = sObjectIds.get(0).getSObjectType();
            //** Get all current fields from the object
            if (sObjectType != null) {
                Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
                for (String fieldName : fieldMap.keySet()) {
                    if (fieldMap.get(fieldName).getDescribe().isCreateable()) {
                        sObjectFields.add(fieldName);
                    }
                }
            }

            //** If there are no records sent into the method, then return an empty list
            if (sObjectIds != null && !sObjectIds.isEmpty() && !sObjectFields.isEmpty()) {
                //** Construct a SOQL query to get all field values of all records (sort Id ascending)
                String sObjectFieldsQuery = 'SELECT ' + sObjectFields.get(0);
                for (Integer i = 1; i < sObjectFields.size(); i++) {
                    sObjectFieldsQuery += ', ' + sObjectFields.get(i);
                }
                sObjectFieldsQuery += ' FROM ' + sObjectType.getDescribe().getName();
                sObjectFieldsQuery += ' WHERE Id IN (\'' + sObjectIds.get(0) + '\'';
                for (Integer i = 1 ; i < sObjectIds.size() ; i++) {
                    sObjectFieldsQuery += ', \'' + sObjectIds.get(i) + '\'';
                }
                sObjectFieldsQuery += ')';
                System.debug('##### sObjectFieldsQuery: ' + sObjectFieldsQuery);
                List<sObject> sObjectFieldsQueryResults = Database.query(sObjectFieldsQuery);

                Map<Id, sObject> mapObjectFieldsQueryResults = new Map<Id, sObject>();
                for (sObject obj : sObjectFieldsQueryResults) {
                    mapObjectFieldsQueryResults.put(obj.Id, obj);
                }
                mapObjectQueries.put(objName, mapObjectFieldsQueryResults);
                System.debug('mapObjectQueries--' + mapObjectQueries);               
            }
        }
        System.debug('myChildRelationships ----- ' + myChildRelationships);
        System.debug('myChildRelationshipRows ----- ' + myChildRelationshipRows);
        System.debug('mapObject--' + mapObject);
        /*constructVFMap();*/
        return null;
    }

    public Pagereference doClone(){
        //** Loop through each level to insert while adding the correct parent identification
        for (Integer currentLevel = 0 ; currentLevel < 20 ; currentLevel++) {

            List<sObject> sObjectsToClone = new List<sObject>();
            List<Id> listIdOld = new List<Id>();
            List<Id> listIdNew = new List<Id>();

            for (sObjectChildRelationship cloneChildRelationship : myChildRelationships) {
                if (cloneChildRelationship.relationshipLevel == currentLevel) {
                    sObjectsToClone = new List<sObject>();

                    for (sObjectChildRelationshipRow cloneChildRelationshipRow :
                            cloneChildRelationship.myChildRelationshipRowList) {

                        System.debug('IS Selected @@@@' + cloneChildRelationshipRow.isSelected );
                        if(cloneChildRelationshipRow.isSelected){
                            listIdOld.add(cloneChildRelationshipRow.sObjectOriginal.Id);
                            
                            sObject orig = mapObjectQueries.get(cloneChildRelationship.relationshipName).get(
                                cloneChildRelationshipRow.sObjectOriginal.Id);

                            sObject clone = orig.getSObjectType().newSObject();
                            Map<String, Schema.SObjectField> fieldMap = clone.getSObjectType().getDescribe().fields.getMap();
                            
                            System.debug('##### Clone: Before = ' + clone);
                            for (String fieldName : fieldMap.keySet()) {
                                if (fieldName != 'Id' && fieldMap.get(fieldName).getDescribe().isCreateable()){
                                    clone.put(fieldName, orig.get(fieldName));
                                    System.debug('##### Clone: Field Clone = ' + fieldName + ': ' + orig.get(fieldName));
                                }
                            }
                            System.debug('cloneChildRelationship.relationshipFieldName--@@##' + cloneChildRelationship.relationshipFieldName);

                            if (cloneChildRelationship.relationshipFieldName != null) {
                                clone.put(cloneChildRelationship.relationshipFieldName, mapIdOldNew.get((Id) mapObjectQueries.get(
                                    cloneChildRelationship.relationshipName).get(cloneChildRelationshipRow.sObjectOriginal.Id).get(
                                    cloneChildRelationship.relationshipFieldName)));
                                System.debug('##### Clone: Field Relationship = ' + cloneChildRelationship.relationshipFieldName +
                                    ': ' + mapIdOldNew.get((Id) mapObjectQueries.get(cloneChildRelationship.relationshipName).get(
                                    cloneChildRelationshipRow.sObjectOriginal.Id).get(
                                    cloneChildRelationship.relationshipFieldName)));
                            }

                            System.debug('##### Clone: After = ' + clone);
                            sObject cloned = clone.clone(false, true);
                            sObjectsToClone.add(cloned);
                            System.debug('##### Clone: Cloned = ' + cloned);
                        }
                    }

                    //** Insert cloned records
                    insert sObjectsToClone;
                    //** Populate list with cloned (new) Ids [assumption is it's the same order as listIdOld]
                    for (sObject newObject : sObjectsToClone) {
                        listIdNew.add(newObject.Id);
                    }
                    //** Fail gracefully if listOldId.size() != listNewId.size()
                    System.assertEquals(listIdNew.size(), listIdOld.size());

                    //** Map the original (old) Ids to the cloned (new) Ids
                    for (Integer i = 0 ; i < listIdOld.size() ; i++) {
                        mapIdOldNew.put(listIdOld.get(i), listIdNew.get(i));
                        
                    }
                }
            }
        }

        /*List<Id> clonedObjectIds = new List<Id>();
        for (sObject originalObject : originalObjects) {
            clonedObjectIds.add(mapIdOldNew.get(originalObject.Id));
        }*/

        Id i = mapIdOldNew.get(parentObj.Id);
        PageReference pg = new PageReference('/'+ i);
        pg.setRedirect(true);
        return pg;
    }

    //cancel method
    public PageReference cancel(){
        PageReference pg = new PageReference('/'+parentObj.Id);
        pg.setRedirect(true);
        return pg;
    }

    // Populate map<objecttypename, List<childpbjectsTOInclude>> from metadata.
    public void getCustomMeatadaRealtions(){
        for(ClonePlusChildRelationShip__mdt  mdt : [Select Label,ChildRelationShip__c,sObjectType__c
                                                        From ClonePlusChildRelationShip__mdt ]){    

            if(relationshipMap.containsKey(mdt.sObjectType__c)){
                Set<String> s = relationshipMap.get(mdt.sObjectType__c);
                s.add(mdt.ChildRelationShip__c);
            }else{
                relationshipMap.put(mdt.sObjectType__c,new Set<String>{mdt.ChildRelationShip__c});
            }                                                           
        }

        System.debug('Relationships---' + relationshipMap);
    }

    // Retrieve fields from field set.
    public static List<String> readFieldSet(String fieldSetName, String ObjectName){
        List<String> fieldApiNameLst = new List<String>();
        System.debug('ObjectName---' + ObjectName);
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = globalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        System.debug('ObjectName---' + ObjectName);
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList);  
        /*return fieldSetObj.getFields(); */

        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()){
            fieldApiNameLst.add(fieldSetMemberObj.getFieldPath());
        }

        return fieldApiNameLst;
    }  

    // Wrapper Classes
    //** Houses the relationship information with the list of related records
    public class sObjectChildRelationship {
        //** What level of child is it?  0=Parent 1=Child 2=Grand-Child 3=Great-Grand-Child etc...
        public Integer relationshipLevel {get; set;}
        //** What table are the related records stored in?
        public String relationshipName {get; set;}
        //** What is the field name that stores the parent-child relationship?
        public String relationshipFieldName {get; set;}
        //** Houses the list of actual records
        public List<sObjectChildRelationshipRow> myChildRelationshipRowList {get; set;}
        //** Initialize
        public sObjectChildRelationship(Integer relationshipLevel,
                String relationshipName,
                String relationshipFieldName,
                List<sObjectChildRelationshipRow> myChildRelationshipRowList) {
            this.relationshipLevel = relationshipLevel;
            this.relationshipName = relationshipName;
            this.relationshipFieldName = relationshipFieldName;
            this.myChildRelationshipRowList = myChildRelationshipRowList;
        }
    }
    
    //** Houses the actual record
    public class sObjectChildRelationshipRow {
        //** What record am I cloning?
        public sObject sObjectOriginal {get; set;}
        public Boolean isSelected {get;set;}
        //** Initialize
        public sObjectChildRelationshipRow(sObject sObjectOriginal,Boolean isSelected) {
            this.sObjectOriginal = sObjectOriginal;
            this.isSelected = isSelected;
        }
    }


}