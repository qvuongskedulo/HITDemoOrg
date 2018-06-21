trigger skedEhrCarePlanGoalTrigger on HealthCloudGA__EhrCarePlanGoal__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrCarePlanGoal__c');
}