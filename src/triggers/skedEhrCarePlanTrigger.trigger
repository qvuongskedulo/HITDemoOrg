trigger skedEhrCarePlanTrigger on HealthCloudGA__EhrCarePlan__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrCarePlan__c');
}