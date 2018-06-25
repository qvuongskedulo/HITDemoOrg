public class skedMappingConfigContainer {
    /************************************************************* Singleton stuff *************************************************************/ 
    private static skedMappingConfigContainer mInstance;
    
    public static skedMappingConfigContainer instance {
        get {
            if (mInstance == null) {
                mInstance = new skedMappingConfigContainer();
            }
            return mInstance;
        }
    }
    
    private skedMappingConfigContainer() {
        this.mapConfig = new Map<string, mappingConfigModel>();
    }

    /************************************************************* AutoMapperconfigContainer *************************************************************/ 
    public static final string SKED_ACTIVITY_OBJECT = 'sked__Activity__c';
    public static final string SKED_AVAILABILITY_OBJECT = 'sked__Availability__c';
    public static final string SKED_CLIENT_AVAILABILITY_OBJECT = 'sked_Client_Availability__c';    
    public static final string SKED_GROUP_ATTENDEE_OBJECT = 'sked_Group_Attendee__c';
    public static final string SKED_GROUP_EVENT_OBJECT = 'sked_Group_Event__c';
    public static final string SKED_JOB_ATTENDEE_OBJECT = 'sked_Job_Attendee__c';
    public static final string SKED_JOB_OBJECT = 'sked__Job__c';
    public static final string SKED_JOB_ALLOCATION_OBJECT = 'sked__Job_Allocation__c';
    public static final string SKED_RESOURCE_OBJECT = 'sked__Resource__c';
    public static final string SKED_SHIFT_OBJECT = 'sked__Shift__c';
    public static final string CONTACT_OBJECT = 'Contact';
    
    protected Map<string, mappingConfigModel> mapConfig;
    
    public mappingConfigModel getMappingConfig(string sObjectType) {
        mappingConfigModel mappingConfig;
        if (!this.mapConfig.containsKey(sObjectType)) {
            if (sObjectType == SKED_AVAILABILITY_OBJECT) {
                mappingConfig = getAvailabilityMappingConfig();
            }
            else if (sObjectType == SKED_ACTIVITY_OBJECT) {
                mappingConfig = getActivityMappingConfig();
            }
            else if (sObjectType == SKED_CLIENT_AVAILABILITY_OBJECT) {
                mappingConfig = getClientAvailabilityMappingConfig();
            }
            else if (sObjectType == SKED_GROUP_ATTENDEE_OBJECT) {
                mappingConfig = getGroupAttendeeMappingConfig();
            }
            else if (sObjectType == SKED_GROUP_EVENT_OBJECT) {
                mappingConfig = getGroupEventMappingConfig();
            }
            else if (sObjectType == SKED_JOB_OBJECT) {
                mappingConfig = getJobMappingConfig();
            }
            else if (sObjectType == SKED_JOB_ALLOCATION_OBJECT) {
                mappingConfig = getJobAllocationMappingConfig();
            }
            else if (sObjectType == SKED_JOB_ATTENDEE_OBJECT) {
                mappingConfig = getJobAttendeeMappingConfig();
            }
            else if (sObjectType == SKED_RESOURCE_OBJECT) {
                mappingConfig = getResourceMappingConfig();
            } 
            else if (sObjectType == SKED_SHIFT_OBJECT) {
                mappingConfig = getShiftMappingConfig();
            }
            else if (sObjectType == CONTACT_OBJECT) {
                mappingConfig = getContactMappingConfig();
            }
            this.mapConfig.put(sObjectType, mappingConfig);
        }
        else {
            mappingConfig = this.mapConfig.get(sObjectType);
        }
        return mappingConfig;
    }
    
    /************************************************************* Private methods *************************************************************/ 
    private mappingConfigModel getActivityMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
        mappingConfig.addFieldConfig('sked__Notes__c', 'notes', 'direct');
        mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked__End__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked__Address__c', 'address', 'fullAddress');
        mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
        mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
        mappingConfig.addFieldConfig('activity', 'objectType', 'value');
        return mappingConfig;
    }
    
    private mappingConfigModel getAvailabilityMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Status__c', 'status', 'direct');
        mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
        mappingConfig.addFieldConfig('sked__Notes__c', 'notes', 'direct');
        mappingConfig.addFieldConfig('sked__Is_Available__c', 'isAvailable', 'direct');
        mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked__Finish__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
        mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
        mappingConfig.addFieldConfig('availability', 'objectType', 'value');
        return mappingConfig;
    }
    
    private mappingConfigModel getClientAvailabilityMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked_Account__c', 'patientId', 'direct');
        mappingConfig.addFieldConfig('sked_Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked_Finish__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked_Preferred_Start__c', 'preferredStart', 'datetime');
        mappingConfig.addFieldConfig('sked_Preferred_Finish__c', 'preferredEnd', 'datetime');
        mappingConfig.addFieldConfig('sked_Service_Location__c', 'serviceLocationId', 'direct');
        mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
        mappingConfig.addFieldConfig('sked_Notes__c', 'notes', 'direct');
        mappingConfig.addFieldConfig('clientAvailability', 'objectType', 'value');
        return mappingConfig;
    }

    private mappingConfigModel getGroupAttendeeMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked_Contact__c', 'contactId', 'direct');
        mappingConfig.addFieldConfig('sked_Group_Event__c', 'groupEventId', 'direct');
        return mappingConfig;
    }

    private mappingConfigModel getGroupEventMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked_Account__c', 'accountId', 'direct');
        mappingConfig.addFieldConfig('sked_Address__c', 'address', 'fullAddress');
        mappingConfig.addFieldConfig('sked_GeoLocation__c', 'address', 'addressLocation');
        mappingConfig.addFieldConfig('sked_Coordinator__c', 'contactId', 'direct');
        mappingConfig.addFieldConfig('sked_Description__c', 'description', 'direct');
        mappingConfig.addFieldConfig('sked_Region__c', 'regionId', 'direct');
        mappingConfig.addFieldConfig('sked_Status__c', 'status', 'direct');
        return mappingConfig;
    }

    private mappingConfigModel getJobMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Account__c', 'accountId', 'direct');
        mappingConfig.addFieldConfig('sked__Account__c', 'patientId', 'direct');
        mappingConfig.addFieldConfig('sked__Address__c', 'address', 'fullAddress');
        mappingConfig.addFieldConfig('sked__Contact__c', 'contactId', 'direct');
        mappingConfig.addFieldConfig('sked__Contact__r.Name', 'contactName', 'direct');
        mappingConfig.addFieldConfig('sked__Description__c', 'description', 'direct');
        mappingConfig.addFieldConfig('sked__Duration__c', 'duration', 'direct');
        mappingConfig.addFieldConfig('sked__Finish__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked__Job_Status__c', 'jobStatus', 'direct');
        mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
        mappingConfig.addFieldConfig('sked__Location__c', 'serviceLocationId', 'direct');
        mappingConfig.addFieldConfig('sked__Notes_Comments__c', 'notes', 'direct');
        mappingConfig.addFieldConfig('sked__Quantity__c', 'notes', 'quantity');
        mappingConfig.addFieldConfig('sked__Recurring_Schedule__c', 'scheduleId', 'direct');
        mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
        mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
        mappingConfig.addFieldConfig('sked_Case__c', 'caseId', 'direct');
        mappingConfig.addFieldConfig('sked_Cancellation_Reason__c', 'cancellationReason', 'direct');
        mappingConfig.addFieldConfig('sked_Cancellation_Reason_Notes__c', 'cancellationReasonNotes', 'direct');
        mappingConfig.addFieldConfig('sked_Is_Care_Team__c', 'isCareTeam', 'direct');
        mappingConfig.addFieldConfig('job', 'objectType', 'value');
        return mappingConfig;
    }
    
    private mappingConfigModel getJobAllocationMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Job__r.sked__Type__c', 'eventType', 'direct');
        mappingConfig.addFieldConfig('sked__Job__r.sked__Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked__Job__r.sked__Finish__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked__Job__r.sked__Address__c', 'address', 'fullAddress');
        mappingConfig.addFieldConfig('sked__Job__r.sked__GeoLocation__c', 'address', 'addressLocation');
        mappingConfig.addFieldConfig('jobAllocation', 'objectType', 'value');
        return mappingConfig;
    }

    private mappingConfigModel getJobAttendeeMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked_Account__c', 'accountId', 'direct');
        mappingConfig.addFieldConfig('sked_Attended__c', 'attended', 'direct');
        mappingConfig.addFieldConfig('sked_Cancellation_Fee__c', 'cancellationFee', 'direct');
        mappingConfig.addFieldConfig('sked_Cancellation_Reason__c', 'cancellationReason', 'direct');
        mappingConfig.addFieldConfig('sked_Contact__c', 'contactId', 'direct');
        mappingConfig.addFieldConfig('sked_Job__c', 'jobId', 'direct');
        mappingConfig.addFieldConfig('sked_Note__c', 'description', 'direct');
        return mappingConfig;
    }

    private mappingConfigModel getResourceMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Category__c', 'category', 'direct');
        mappingConfig.addFieldConfig('sked__Primary_Region__c', 'regionId', 'direct');
        mappingConfig.addFieldConfig('sked__User__c', 'userId', 'direct');
        mappingConfig.addFieldConfig('sked__User__r.SmallPhotoUrl', 'photoUrl', 'direct');
        mappingConfig.addFieldConfig('sked__Home_Address__c', 'address', 'fullAddress');
        mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
        return mappingConfig;
    }

    private mappingConfigModel getShiftMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('Name', 'name', 'direct');
        mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
        mappingConfig.addFieldConfig('sked__Location__c', 'locationId', 'direct');
        mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
        mappingConfig.addFieldConfig('sked__End__c', 'end', 'datetime');
        mappingConfig.addFieldConfig('sked__Duration__c', 'duration', 'direct');
        mappingConfig.addFieldConfig('sked_Actual_Start__c', 'actualStart', 'datetime');
        mappingConfig.addFieldConfig('sked_Actual_End__c', 'actualEnd', 'datetime');
        mappingConfig.addFieldConfig('shift', 'objectType', 'value');
        return mappingConfig;
    }

    private mappingConfigModel getContactMappingConfig() {
        mappingConfigModel mappingConfig = new mappingConfigModel();
        mappingConfig.addFieldConfig('Id', 'id', 'direct');
        mappingConfig.addFieldConfig('FirstName', 'firstName', 'direct');
        mappingConfig.addFieldConfig('LastName', 'lastName', 'direct');
        mappingConfig.addFieldConfig('Email', 'email', 'direct');
        mappingConfig.addFieldConfig('Phone', 'phone', 'direct');
        mappingConfig.addFieldConfig('Birthdate', 'birthdate', 'direct');
        mappingConfig.addFieldConfig('AccountId', 'accountId', 'direct');
        return mappingConfig;
    }
    
    /************************************************************* Nested class *************************************************************/ 
    public class mappingConfigModel {
        public List<fieldConfigModel> fieldConfigs {get;set;}
        
        public mappingConfigModel() {
            this.fieldConfigs = new List<fieldConfigModel>();
        }
        
        public void addFieldConfig(string sObjectFieldPath, string domainFieldName, string mappingType) {
            fieldConfigModel fieldConfig = new fieldConfigModel();
            fieldConfig.sObjectFieldPaths = sObjectFieldPath.split('\\.');
            fieldConfig.domainFieldName = domainFieldName;
            fieldConfig.mappingType = mappingType;
            this.fieldConfigs.add(fieldConfig);
        }
    }
    
    public class fieldConfigModel {
        public List<string> sObjectFieldPaths {get;set;}
        public string domainFieldName {get;set;}
        public string mappingType {get;set;}
    }
    
}