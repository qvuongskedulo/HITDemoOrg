public virtual class skedGroupEventService {
    public string sObjectApiName = '';

    public skedGroupEventService() {
        initialize();
    }
    /*********************************************************** Protected **************************************************************/
    protected void initialize() {
    }

    protected void doAdditionalMap(sObject sObj, skedModels.modelBase modelBase) {
    }

    protected saveResult preSaveRecord(skedModels.modelBase modelBase, List<sObject> allRecords) {
        saveResult result = new saveResult();
        result.success = true;
        return result;
    }

    protected void postSaveRecord(skedModels.modelBase modelBase, List<sObject> allRecords) {}
    
    /*********************************************************** Public ******************************************************************/
    public sObject mapTosObject(skedModels.groupEvent groupEventModel, string sObjectName) {
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectName);
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

        string serializedModel = JSON.serialize(groupEventModel);
        Map<String, Object> untypedDomainMap = (Map<String, Object>) JSON.deserializeUntyped(serializedModel);
        sObject sObj = sObjectType.newSObject();

        string startFieldApiName, finishFieldApiName, addressFieldApiName, addressLocationFieldApiName;

        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            if (fieldConfig.mappingType == 'direct' && fieldConfig.sObjectFieldPaths.size() == 1) {
                string sObjectFieldApiName = fieldConfig.sObjectFieldPaths.get(0);

                if (untypedDomainMap.containsKey(fieldConfig.domainFieldName)) {
                    Object value = untypedDomainMap.get(fieldConfig.domainFieldName);
                    if (value != null) {
                        sObj.put(sObjectFieldApiName, value);
                    }
                }
            }
            else if (fieldConfig.mappingType == 'datetime' && fieldConfig.domainFieldName == 'start') {
                startFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'datetime' && fieldConfig.domainFieldName == 'end') {
                finishFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'fullAddress' && fieldConfig.domainFieldName == 'address') {
                addressFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'addressLocation' && fieldConfig.domainFieldName == 'address') {
                addressLocationFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
        }

        if (groupEventModel.address != null) {
            if (!string.isBlank(addressFieldApiName) && !string.isBlank(groupEventModel.address.fullAddress)) {
                sObj.put(addressFieldApiName, groupEventModel.address.fullAddress);
            }
            if (!string.isBlank(addressLocationFieldApiName) && groupEventModel.address.geometry != null) {
                string addressLatFieldApiName = addressLocationFieldApiName.replace('__c', '__latitude__s');
                sObj.put(addressLatFieldApiName, groupEventModel.address.geometry.lat);

                string addressLngFieldApiName = addressLocationFieldApiName.replace('__c', '__longitude__s');
                sObj.put(addressLngFieldApiName, groupEventModel.address.geometry.lng);
            }
        }

        doAdditionalMap(sObj, groupEventModel);

        return sObj;
    }

    public sObject mapTosObject(skedModels.groupClient groupClientModel, string sObjectName) {
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectName);
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

        string serializedModel = JSON.serialize(groupClientModel);
        Map<String, Object> untypedDomainMap = (Map<String, Object>) JSON.deserializeUntyped(serializedModel);
        sObject sObj = sObjectType.newSObject();

        string startFieldApiName, finishFieldApiName, addressFieldApiName, addressLocationFieldApiName;

        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            if (fieldConfig.mappingType == 'direct' && fieldConfig.sObjectFieldPaths.size() == 1) {
                string sObjectFieldApiName = fieldConfig.sObjectFieldPaths.get(0);

                if (untypedDomainMap.containsKey(fieldConfig.domainFieldName)) {
                    Object value = untypedDomainMap.get(fieldConfig.domainFieldName);
                    if (value != null) {
                        sObj.put(sObjectFieldApiName, value);
                    }
                }
            }
            else if (fieldConfig.mappingType == 'datetime' && fieldConfig.domainFieldName == 'start') {
                startFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'datetime' && fieldConfig.domainFieldName == 'end') {
                finishFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'fullAddress' && fieldConfig.domainFieldName == 'address') {
                addressFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
            else if (fieldConfig.mappingType == 'addressLocation' && fieldConfig.domainFieldName == 'address') {
                addressLocationFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            }
        }

        doAdditionalMap(sObj, groupClientModel);

        return sObj;
    }

    public saveResult saveRecord(skedModels.groupEvent groupEventModel) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(groupEventModel, 'sked_Group_Event__c');
        allRecords.add(record);

        saveResult result = preSaveRecord(groupEventModel, allRecords);
        if (result.success == true) {
            if (string.isBlank(groupEventModel.id)) {
                insert allRecords;
            }
            else {
                update allRecords;
            }

            postSaveRecord(groupEventModel, allRecords);
            result.savedObjects = allRecords;
        }
        return result;
    }

    public skedModels.groupEvent getGroupEvent(skedModels.groupEvent groupEventModel) {
        List<sked_Group_Event__c> groupEventEntities = [SELECT Id, Name, sked_Account__c, sked_Account__r.Name, sked_Address__c, 
                                                            sked_Coordinator__c, sked_Coordinator__r.Name, sked_Description__c, 
                                                            sked_GeoLocation__Longitude__s, sked_GeoLocation__Latitude__s, 
                                                            sked_Region__c, sked_Region__r.Name, sked_Status__c
                                                        FROM sked_Group_Event__c
                                                        WHERE Id = :groupEventModel.Id AND sked_Is_Active__c = TRUE];
        if (groupEventEntities == null || groupEventEntities.size() == 0) {
            throw new skedException('No Group Event found');
        }

        skedModels.groupEvent groupEvent = new skedModels.groupEvent(groupEventEntities[0]);

        return groupEvent;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public virtual class saveModelBase {
        public skedModels.event event {get;set;}
        public skedRecurringFactory.recurringOption recurringOptions {get;set;}
    }

    public virtual class saveResult {
        public List<sObject> savedObjects {get;set;}
        public boolean success {get;set;}
        public object returnedData {get;set;}
    }

    /*********************************************************** GROUP CLIENT ************************************************************/
    public saveResult saveGroupClient(skedModels.groupClient groupClientModel) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(groupClientModel, 'sked_Group_Client__c');
        allRecords.add(record);

        saveResult result = preSaveRecord(groupClientModel, allRecords);
        if (result.success == true) {
            if (string.isBlank(groupClientModel.id)) {
                insert allRecords;
            }
            else {
                update allRecords;
            }

            postSaveRecord(groupClientModel, allRecords);
            result.savedObjects = allRecords;
        }
        return result;
    }

    public void deleteGroupClient(skedModels.groupClient groupClientModel) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(groupClientModel, 'sked_Group_Event__c');
        allRecords.add(record);

        delete allRecords;
    }
}