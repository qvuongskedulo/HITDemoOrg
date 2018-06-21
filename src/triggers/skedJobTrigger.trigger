trigger skedJobTrigger on sked__Job__c (before insert, after update, after insert) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('sked__Job__c'); 
    
    if (trigger.isBefore) {
        if (trigger.isInsert) {
            skedJobHandler.beforeInsert(trigger.new);
        }
    }
    else if (trigger.isAfter) {
        if (trigger.isUpdate) {
            skedJobHandler.afterUpdate(trigger.new, trigger.oldMap);
        }
    }
}