trigger skedCarePlanProblemTrigger on HealthCloudGA__CarePlanProblem__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__CarePlanProblem__c');
}