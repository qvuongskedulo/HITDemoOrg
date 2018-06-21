global class skedActivityService extends skedEventServiceBase {

    protected override void initialize() {
        this.sObjectApiName = 'sked__Activity__c';
        this.startFieldApiName = 'sked__Start__c';
        this.finishFieldApiName = 'sked__End__c';
        this.templateEntryApiName = 'sked_Template_Entry__c';
        this.scheduleFieldApiName = 'sked_Recurring_Schedule__c';
        
        this.fieldsToTrackChange = new List<string>();
        this.fieldsToTrackChange.add('sked__Address__c');
        this.fieldsToTrackChange.add('sked__GeoLocation__Latitude__s');
        this.fieldsToTrackChange.add('sked__GeoLocation__Longitude__s');
        this.fieldsToTrackChange.add('sked__Notes__c');
        this.fieldsToTrackChange.add('sked__Type__c');
    }
    
    protected override void doAdditionalMap(sObject sObj, skedModels.event model) {
        sked__Activity__c skedActivity = (sked__Activity__c)sObj;
        skedModels.activity activity = (skedModels.activity)model;
        if (string.isBlank(activity.id)) {
            skedActivity.sked__Resource__c = activity.resourceId;
        }
	}
    
}