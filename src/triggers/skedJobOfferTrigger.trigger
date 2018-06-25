trigger skedJobOfferTrigger on sked_Job_Offer__c (after update) {
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            skedJobOfferHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}