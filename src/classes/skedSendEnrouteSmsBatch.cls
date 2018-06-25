global class skedSendEnrouteSmsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    protected list<sked__Job_Allocation__c> enrouteAllocations;
    
    global skedSendEnrouteSmsBatch(List<sked__Job_Allocation__c> inputAllocations) {
        enrouteAllocations = inputAllocations;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {        
        return enrouteAllocations;
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> scope) {
        Set<Id> allocationIds = new Set<Id>();
        
        for (sked__Job_Allocation__c allocation : scope) {
            allocationIds.add(allocation.Id);
        }
        if (!allocationIds.isEmpty()) {
            skedSmsApiManager.sendNexmoEnrouteSms(allocationIds);
        }        
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }   
    
}