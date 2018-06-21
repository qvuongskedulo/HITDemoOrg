public class skedJobHandler {
    
    public static void beforeInsert(List<sked__Job__c> newRecords) {
        populateData(newRecords);
    }
	
    public static void afterUpdate(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> updatedRecords) {
        deleteJobAllocations(newRecords, updatedRecords);
    }
    
    private static void populateData(List<sked__Job__c> newRecords) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        for (sked__Job__c record : newRecords) {
            if (record.sked__Contact__c != null) {
                contactIds.add(record.sked__Contact__c);
            }
            if (record.sked_Case__c != null) {
                caseIds.add(record.sked_Case__c);
            }
        }
        if (!contactIds.isEmpty()) {
            Map<Id, Contact> mapContact = new Map<Id, Contact>([SELECT Id, Description
                                                                FROM Contact
                                                                WHERE Id IN:contactIds]);
            for (sked__Job__c record : newRecords) {
                if (record.sked__Contact__c != null) {
                    Contact contact = mapContact.get(record.sked__Contact__c);
                    record.sked_Highlighted_Alerts__c = contact.Description;
                }
            }
        }
        if (!caseIds.isEmpty()) {
            List<sked_Support_Plan__c> supportPlans = [SELECT Id, sked_Case__c
                                                       FROM sked_Support_Plan__c
                                                       WHERE sked_Case__c IN:caseIds];
            Map<Id, Id> map_caseId_supportPlanId = new Map<Id, Id>();
            for (sked_Support_Plan__c supportPlan : supportPlans) {
                map_caseId_supportPlanId.put(supportPlan.sked_Case__c, supportPlan.Id);
            }
            for (sked__Job__c record : newRecords) {
                if (record.sked_Case__c != null && map_caseId_supportPlanId.containsKey(record.sked_Case__c)) {
                    record.sked_Support_Plan__c = map_caseId_supportPlanId.get(record.sked_Case__c);
                }
            }
        }
    }
    
    private static void deleteJobAllocations(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> updatedRecords) {
        Set<Id> jobIdsToDeleteAllocations = new Set<Id>();
        for (sked__Job__c newData : newRecords) {
            sked__Job__c oldData = updatedRecords.get(newData.Id);
            if (newData.sked__Job_Status__c != oldData.sked__Job_Status__c) {
                if (newData.sked__Job_Status__c == skedConstants.JOB_STATUS_CANCELLED) {
                    jobIdsToDeleteAllocations.add(newData.Id);
                }
            }   
        }
        if (!jobIdsToDeleteAllocations.isEmpty()) {
            List<sked__Job_Allocation__c> allocationsToDelete = [SELECT Id
                                                                 FROM sked__Job_Allocation__c
                                                                 WHERE sked__Job__c IN :jobIdsToDeleteAllocations
                                                                 AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                                 AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            for (sked__Job_Allocation__c skedAllocation : allocationsToDelete) {
                skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
            }
            update allocationsToDelete;
        }
    }
    
}