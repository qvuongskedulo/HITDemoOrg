public class skedJobAllocationHandler  {

    public static void afterInsert(list<sked__Job_Allocation__c> newRecords) {
        
    }

    public static void afterUpdate(list<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> updatedRecords) {
        handleDispatchAllocations(newRecords, updatedRecords);
    }

    /**************************************** PRIVATE METHOD ********************************************/
    private static void handleDispatchAllocations(List<sked__Job_Allocation__c> newRecords, Map<Id, sked__Job_Allocation__c> updatedRecords) {
        List<sked__Job_Allocation__c> allocationsToDispatch = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c allocation : newRecords) {
            sked__Job_Allocation__c oldData = updatedRecords.get(allocation.Id);
            if (allocation.sked__Status__c != oldData.sked__Status__c && allocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED) {
                allocationsToDispatch.add(allocation);
            }
        }
        if (!allocationsToDispatch.isEmpty()) {
            skedNotifyDispatchedJobsBatch batch = new skedNotifyDispatchedJobsBatch(allocationsToDispatch);
            Database.executeBatch(batch, 20);
        }
    }

}