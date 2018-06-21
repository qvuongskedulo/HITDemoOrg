trigger skedJobAllocationTrigger on sked__Job_Allocation__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute(sked__Job_Allocation__c.sObjectType.getDescribe().getName());
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            skedJobAllocationHandler.afterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            skedJobAllocationHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}