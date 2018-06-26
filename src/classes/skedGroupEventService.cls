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

    protected saveResult preSaveRecord(List<skedModels.modelBase> modelBases, List<sObject> allRecords) {
        saveResult result = new saveResult();
        result.success = true;
        return result;
    }

    protected void postSaveRecord(skedModels.modelBase modelBase, List<sObject> allRecords) {}
    protected void postSaveRecord(List<skedModels.modelBase> modelBases, List<sObject> allRecords) {}
    
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

    public sObject mapTosObject(skedModels.groupAttendee groupAttendeeModel, string sObjectName) {
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectName);
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

        string serializedModel = JSON.serialize(groupAttendeeModel);
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

        doAdditionalMap(sObj, groupAttendeeModel);

        return sObj;
    }

    public sObject mapTosObject(skedModels.groupTag groupTagModel, string sObjectName) {
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectName);
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

        string serializedModel = JSON.serialize(groupTagModel);
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
        }

        doAdditionalMap(sObj, groupTagModel);

        return sObj;
    }

    public saveResult saveRecord(skedModels.groupEvent groupEventModel) {
        List<skedModels.groupEvent> groupEventModels = new List<skedModels.groupEvent>();
        groupEventModels.add(groupEventModel);

        return saveRecord(groupEventModels);
    }

    public saveResult saveRecord(List<skedModels.groupEvent> groupEventModels) {
        List<sObject> updateRecords = new List<sObject>();
        List<sObject> insertRecords = new List<sObject>();
        for (skedModels.groupEvent groupEvent : groupEventModels) {
            sObject record = mapTosObject(groupEvent, 'sked_Group_Event__c');
            if (string.isBlank(groupEvent.id)) {
                insertRecords.add(record);
            }
            else {
                updateRecords.add(record);
            }
        }

        saveResult insertResult = preSaveRecord(groupEventModels, insertRecords);
        if (insertResult.success == true) {
            if (insertRecords != null && insertRecords.size() > 0) {
                insert insertRecords;
            }

            postSaveRecord(groupEventModels, insertRecords);
        }

        saveResult updateResult = preSaveRecord(groupEventModels, updateRecords);
        if (updateResult.success == true) {
            if (updateRecords != null && updateRecords.size() > 0) {
                update updateRecords;
            }

            postSaveRecord(groupEventModels, updateRecords);
        }

        saveResult result = new saveResult();
        result.success = updateResult.success && insertResult.success;
        result.savedObjects.addAll(insertRecords);
        result.savedObjects.addAll(updateRecords);

        return result;
    }

    public skedModels.groupEvent getGroupEvent(skedModels.groupEvent groupEventModel) {
        List<sked_Group_Event__c> groupEventEntities = [SELECT Id, Name, sked_Account__c, sked_Account__r.Name, sked_Address__c, 
                                                            sked_Coordinator__c, sked_Coordinator__r.Name, sked_Description__c, 
                                                            sked_GeoLocation__Longitude__s, sked_GeoLocation__Latitude__s, 
                                                            sked_Region__c, sked_Region__r.Name, sked_Status__c,
                                                            (SELECT Id, Name, sked_Contact__r.AccountId, sked_Contact__r.Birthdate, sked_Contact__r.Email, 
                                                                    sked_Contact__r.FirstName, sked_Contact__r.LastName, sked_Contact__r.Phone,
                                                                    sked_Contact__r.MailingCity, sked_Contact__r.MailingCountry, sked_Contact__r.MailingPostalCode, 
                                                                    sked_Contact__r.MailingState, sked_Contact__r.MailingStreet, sked_Contact__r.MailingLatitude, 
                                                                    sked_Contact__r.MailingLongitude
                                                            FROM sked_Group_Attendees__r)
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

    public virtual class ClassName {
        
    }

    /*********************************************************** GROUP ATTENDEE ************************************************************/
    public saveResult saveRecord(skedModels.groupAttendee groupAttendeeModel) {
        List<skedModels.groupAttendee> groupAttendeeModels = new List<skedModels.groupAttendee>();
        groupAttendeeModels.add(groupAttendeeModel);

        return saveRecord(groupAttendeeModels);
    }

    public saveResult saveRecord(List<skedModels.groupAttendee> groupAttendeeModels) {
        List<sObject> updateRecords = new List<sObject>();
        List<sObject> insertRecords = new List<sObject>();
        for (skedModels.groupAttendee groupAttendee : groupAttendeeModels) {
            sObject record = mapTosObject(groupAttendee, 'sked_Group_Attendee__c');
            if (string.isBlank(groupAttendee.id)) {
                insertRecords.add(record);
            }
            else {
                updateRecords.add(record);
            }
        }

        saveResult insertResult = preSaveRecord(groupAttendeeModels, insertRecords);
        if (insertResult.success == true) {
            if (insertRecords != null && insertRecords.size() > 0) {
                insert insertRecords;
            }

            postSaveRecord(groupAttendeeModels, insertRecords);
        }

        saveResult updateResult = preSaveRecord(groupAttendeeModels, updateRecords);
        if (updateResult.success == true) {
            if (updateRecords != null && updateRecords.size() > 0) {
                update updateRecords;
            }

            postSaveRecord(groupAttendeeModels, updateRecords);
        }

        saveResult result = new saveResult();
        result.success = updateResult.success && insertResult.success;
        result.savedObjects.addAll(insertRecords);
        result.savedObjects.addAll(updateRecords);

        return result;
    }

    public void deleteGroupClient(skedModels.groupAttendee groupAttendeeModel) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(groupAttendeeModel, 'sked_Group_Attendee__c');
        allRecords.add(record);

        delete allRecords;
    }

    /*********************************************************** GROUP TAG ****************************************************************/
    public saveResult saveRecord(skedModels.groupTag groupTagModel) {
        List<skedModels.groupTag> groupTagModels = new List<skedModels.groupTag>();
        groupTagModels.add(groupTagModel);

        return saveRecord(groupTagModels);
    }

    public saveResult saveRecord(List<skedModels.groupTag> groupTagModels) {
        List<sObject> updateRecords = new List<sObject>();
        List<sObject> insertRecords = new List<sObject>();
        for (skedModels.groupTag groupTag : groupTagModels) {
            sObject record = mapTosObject(groupTag, 'sked_Group_Tag__c');
            if (string.isBlank(groupTag.id)) {
                insertRecords.add(record);
            }
            else {
                updateRecords.add(record);
            }
        }

        saveResult insertResult = preSaveRecord(groupTagModels, insertRecords);
        if (insertResult.success == true) {
            if (insertRecords != null && insertRecords.size() > 0) {
                insert insertRecords;
            }

            postSaveRecord(groupTagModels, insertRecords);
        }

        saveResult updateResult = preSaveRecord(groupTagModels, updateRecords);
        if (updateResult.success == true) {
            if (updateRecords != null && updateRecords.size() > 0) {
                update updateRecords;
            }

            postSaveRecord(groupTagModels, updateRecords);
        }

        saveResult result = new saveResult();
        result.success = updateResult.success && insertResult.success;
        result.savedObjects.addAll(insertRecords);
        result.savedObjects.addAll(updateRecords);

        return result;
    }
}