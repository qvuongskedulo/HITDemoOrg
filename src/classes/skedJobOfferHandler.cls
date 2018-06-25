public class skedJobOfferHandler {
    
    public static void afterUpdate(List<sked_Job_Offer__c> newRecords, Map<Id, sked_Job_Offer__c> updatedRecords) {
        onOfferAccepted(newRecords, updatedRecords);
    }

    private static void onOfferAccepted(List<sked_Job_Offer__c> newRecords, Map<Id, sked_Job_Offer__c> updatedRecords) {
    	List<sked_Job_Offer__c> acceptedOffers = new List<sked_Job_Offer__c>();
    	Set<Id> jobIds = new Set<Id>();
    	for (sked_Job_Offer__c newRecord : newRecords) {
    		sked_Job_Offer__c oldData = updatedRecords.get(newRecord.Id);
    		if (newRecord.sked_Status__c != oldData.sked_Status__c && newRecord.sked_Status__c == skedConstants.JOB_OFFER_STATUS_ACCEPTED) {
    			acceptedOffers.add(newRecord);
    			jobIds.add(newRecord.sked_Job__c);
    		}
    	}
    	if (!acceptedOffers.isEmpty()) {
    		List<sked__Job_Allocation__c> newSkedAllocations = new List<sked__Job_Allocation__c>();
    		for (sked_Job_Offer__c acceptedOffer : acceptedOffers) {
    			sked__Job_Allocation__c skedAllocation = new sked__Job_Allocation__c(
    				sked__Job__c = acceptedOffer.sked_Job__c,
    				sked__Resource__c = acceptedOffer.sked_Resource__c,
    				sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_CONFIRMED,
                    sked__Estimated_Travel_Time__c = acceptedOffer.sked_Estimated_Travel_Time__c,
                    sked_Estimated_Distance__c = acceptedOffer.sked_Estimated_Distance__c
				);
				newSkedAllocations.add(skedAllocation);
    		}
    		insert newSkedAllocations;
    	}
    }
    
}