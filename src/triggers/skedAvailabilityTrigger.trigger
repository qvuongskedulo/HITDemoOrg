trigger skedAvailabilityTrigger on sked__Availability__c (after insert, after update) {
	
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            skedAvailabilityHandler.afterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            skedAvailabilityHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}