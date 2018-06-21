trigger skedEhrPractitionerQualificationTrigger on HealthCloudGA__EhrPractitionerQualification__c (after insert, after update, before delete) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrPractitionerQualification__c'); 
}