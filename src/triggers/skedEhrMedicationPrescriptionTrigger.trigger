trigger skedEhrMedicationPrescriptionTrigger on HealthCloudGA__EhrMedicationPrescription__c (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('HealthCloudGA__EhrMedicationPrescription__c');
}