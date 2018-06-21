trigger skedEhrRelatedPersonTrigger on HealthCloudGA__EhrRelatedPerson__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrRelatedPerson__c');
}