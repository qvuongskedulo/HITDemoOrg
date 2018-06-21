trigger skedSupportPlanTrigger on sked_Support_Plan__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            skedSupportPlanUtils.setSupportPlanInactive(trigger.newMap, trigger.oldMap);
        }
        else if (Trigger.isUpdate) {
            skedSupportPlanUtils.setSupportPlanInactive(trigger.newMap, trigger.oldMap);
        }
    }
}