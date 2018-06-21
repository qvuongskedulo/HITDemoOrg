global class skedAvailabilityService extends skedEventServiceBase {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked__Availability__c';
        this.startFieldApiName = 'sked__Start__c';
        this.finishFieldApiName = 'sked__Finish__c';
        this.templateEntryApiName = 'sked_Template_Entry__c';
        this.scheduleFieldApiName = 'sked_Recurring_Schedule__c';
        
        this.fieldsToTrackChange = new List<string>();
        this.fieldsToTrackChange.add('sked__Is_Available__c');
        this.fieldsToTrackChange.add('sked__Notes__c');
        this.fieldsToTrackChange.add('sked__Type__c');
        this.fieldsToTrackChange.add('sked_Is_All_Day__c');
    }
    
    protected override void doAdditionalMap(sObject sObj, skedModels.event model) {
        sked__Availability__c skedAvailability = (sked__Availability__c)sObj;
        skedModels.availability availability = (skedModels.availability)model;
        if (string.isBlank(availability.id)) {
            skedAvailability.sked__Resource__c = availability.resourceId;
        }
	}

}