global class skedTrackingLocationSchedule implements Schedulable {
	
    global void execute(SchedulableContext sc) {
		DateTime currentTime = system.now();
        DateTime startTime = currentTime.addDays(-1);
        DateTime endTime = currentTime;
        
        Map<Id, sked__Resource__c> mapSkedResource = new Map<Id, sked__Resource__c>([SELECT Id
                                                                                     FROM sked__Resource__c
                                                                                     WHERE sked__Is_Active__c = TRUE]);
        
        skedTrackingResourceLocationBatch b = new skedTrackingResourceLocationBatch(mapSkedResource.keySet(), startTime, endTime);
        Database.executeBatch(b, 20);
	}
    
}