trigger skedEhrObservationTrigger on HealthCloudGA__EhrObservation__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrObservation__c');
}