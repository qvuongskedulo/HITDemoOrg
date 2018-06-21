public class skedAvailabilityHandler {
    
    public static void afterInsert(List<sked__Availability__c> newRecords) {
        captureExceptionLogs(newRecords);
    }
    
    public static void afterUpdate(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> updatedRecords) {
        captureExceptionLogs(newRecords, updatedRecords);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    private static void captureExceptionLogs(List<sked__Availability__c> newRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
		for (sked__Availability__c newRecord : newRecords) {
			if (newRecord.sked__Is_Available__c || newRecord.sked__Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED) {
				continue;
			}
			skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
			unavailability.resourceId = newRecord.sked__Resource__c;
			unavailability.startTime = newRecord.sked__Start__c;
			unavailability.endTime = newRecord.sked__Finish__c;
			unavailability.exceptionCode = newRecord.sked__Type__c;
            unavailability.availabilityId = newRecord.Id;
			unavailabilityList.add(unavailability);
		}
		if (!unavailabilityList.isEmpty()) {
			skedExceptionLogService.captureExceptions(unavailabilityList);
		}
    }
    
    private static void captureExceptionLogs(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> updatedRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        for (sked__Availability__c record : updatedRecords.values()) {
            if (record.sked__Is_Available__c || record.sked__Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED) {
                continue;
            }
            sked__Availability__c oldRecord = updatedRecords.get(record.Id);
            if (record.sked__Start__c != oldRecord.sked__Start__c || record.sked__Finish__c != oldRecord.sked__Finish__c) {
                skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                unavailability.resourceId = record.sked__Resource__c;
                unavailability.startTime = record.sked__Start__c;
                unavailability.endTime = record.sked__Finish__c;
                unavailability.exceptionCode = record.sked__Type__c;
                unavailability.availabilityId = record.Id;
                unavailabilityList.add(unavailability);
            }
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService.captureExceptions(unavailabilityList);
        }
    }
    
}