trigger skedPractitionerTrigger on HealthCloudGA__EhrPractitioner__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrPractitioner__c');
}