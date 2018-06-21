public abstract class skedEventServiceBase {

	protected string sObjectApiName {get;set;}
    protected string startFieldApiName {get;set;}
    protected string finishFieldApiName {get;set;}
    protected string scheduleFieldApiName {get;set;}
    protected string templateEntryApiName {get;set;}
    protected List<string> fieldsToTrackChange {get;set;}

	public skedEventServiceBase() {
		initialize();
	}
	/*********************************************************** Protected ***********************************************************/
	protected abstract void initialize();

	protected virtual void doAdditionalMap(sObject sObj, skedModels.event eventModel) {
	}

	protected virtual saveResult preSaveRecord(skedModels.event eventModel, List<sObject> allRecords) {
		saveResult result = new saveResult();
		result.success = true;
		return result;
	}

	protected virtual void postSaveRecord(skedModels.event eventModel, List<sObject> allRecords) {}
    
    /*********************************************************** Public ***********************************************************/
	public virtual sObject mapTosObject(skedModels.event eventModel) {
		skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(this.sObjectApiName);
		Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(this.sObjectApiName);

		string serializedModel = JSON.serialize(eventModel);
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

		if (!string.isBlank(startFieldApiName) && !string.isBlank(eventModel.startDate) && eventModel.startTime != null) {
			Date startDate = skedDateTimeUtils.getDateFromIsoString(eventModel.startDate);
	        integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(eventModel.startTime);
	        DateTime startDateDt = skedDateTimeUtils.getStartOfDate(startDate, eventModel.timezoneSidId);
	        DateTime start = skedDateTimeUtils.addMinutes(startDateDt, startTimeInMinutes, eventModel.timezoneSidId);
	        sObj.put(startFieldApiName, start);
		}

		if (!string.isBlank(finishFieldApiName) && !string.isBlank(eventModel.endDate) && eventModel.endTime != null) {
			Date endDate = skedDateTimeUtils.getDateFromIsoString(eventModel.endDate);
	        integer endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(eventModel.endTime);
	        DateTime endDateDt = skedDateTimeUtils.getStartOfDate(endDate, eventModel.timezoneSidId);
	        DateTime finish = skedDateTimeUtils.addMinutes(endDateDt, endTimeInMinutes, eventModel.timezoneSidId);
	        sObj.put(finishFieldApiName, finish);
		}

		if (eventModel.address != null) {
			if (!string.isBlank(addressFieldApiName) && !string.isBlank(eventModel.address.fullAddress)) {
				sObj.put(addressFieldApiName, eventModel.address.fullAddress);
			}
			if (!string.isBlank(addressLocationFieldApiName) && eventModel.address.geometry != null) {
				string addressLatFieldApiName = addressLocationFieldApiName.replace('__c', '__latitude__s');
				sObj.put(addressLatFieldApiName, eventModel.address.geometry.lat);

				string addressLngFieldApiName = addressLocationFieldApiName.replace('__c', '__longitude__s');
				sObj.put(addressLngFieldApiName, eventModel.address.geometry.lng);
			}
		}

		doAdditionalMap(sObj, eventModel);

		return sObj;
	}

	public saveResult saveRecord(skedModels.event eventModel) {
		return saveRecord(eventModel, null);
	}

	public saveResult saveRecord(skedModels.event eventModel, skedRecurringFactory.recurringOption recurringOptions) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(eventModel);
        
        if (recurringOptions == null) {
        	allRecords.add(record);
        }
        else {
            recurringOptions.timezoneSidId = eventModel.timezoneSidId;
            recurringOptions.startFieldApiName = this.startFieldApiName;
            recurringOptions.finishFieldApiName = this.finishFieldApiName;
            recurringOptions.templateEntryApiName = this.templateEntryApiName;
            recurringOptions.scheduleFieldApiName = this.scheduleFieldApiName;
            recurringOptions.fieldsToTrackChange = this.fieldsToTrackChange;
            
            if (string.isBlank(eventModel.id)) {
                List<sObject> recurringRecords = skedRecurringFactory.processRecurring(record, recurringOptions);
                allRecords.addAll(recurringRecords);
            }
            else {
                List<sObject> recurringRecords = skedRecurringFactory.editRecurring(record, recurringOptions);
                allRecords.addAll(recurringRecords);
            }
        }

        saveResult result = preSaveRecord(eventModel, allRecords);
        if (result.success == true) {
        	if (string.isBlank(eventModel.id)) {
        		insert allRecords;
        	}
        	else {
	        	update allRecords;
        	}

	        postSaveRecord(eventModel, allRecords);
	        result.savedObjects = allRecords;
	    }
	    return result;
    }

	public void deleteRecord(skedModels.event eventModel) {
		deleteRecord(eventModel, null);
	}

    public virtual void deleteRecord(skedModels.event eventModel, skedRecurringFactory.recurringOption recurringOptions) {
        List<sObject> allRecords = new List<sObject>();
        sObject record = mapTosObject(eventModel);
        allRecords.add(record);

        if (recurringOptions != NULL) {
            recurringOptions.timezoneSidId = eventModel.timezoneSidId;
            recurringOptions.startFieldApiName = this.startFieldApiName;
            recurringOptions.finishFieldApiName = this.finishFieldApiName;
            recurringOptions.isDeleting = true;
            recurringOptions.scheduleFieldApiName = this.scheduleFieldApiName;
            List<sObject> recurringRecords = skedRecurringFactory.editRecurring(record, recurringOptions);
            allRecords.addAll(recurringRecords);
        }
        delete allRecords;
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
}