global class skedOfferService {
	
    public sked_Offer__c saveRecord(skedModels.offer model) {
        sked_Offer__c skedOffer = new sked_Offer__c(
        	Id = model.id,
            sked_Case__c = model.caseId,
            sked_Description__c = model.description,
            sked_Status__c = skedConstants.OFFER_STATUS_NEW
        );
        upsert skedOffer;
        
        return getOfferById(skedOffer.Id);
    }
    
    public sked_Offer__c stopOffer(stopOfferModel model) {
        sked_Offer__c skedOffer = new sked_Offer__c(
            Id = model.offerId,
            sked_Status__c = skedConstants.OFFER_STATUS_STOPPED
        );
        upsert skedOffer;
        
        return getOfferById(skedOffer.Id);
    }

    public static List<skedModels.offer> getPatientOffers(string patientId) {
        List<skedModels.offer> results = new List<skedModels.offer>();
        List<sked_Offer__c> skedOffers = [SELECT Id, Name, sked_Case__c, sked_Description__c, sked_Status__c
                                          FROM sked_Offer__c
                                          WHERE sked_Case__r.AccountId = :patientId
                                          ORDER BY LastModifiedDate DESC];
        for (sked_Offer__c skedOffer : skedOffers) {
            skedModels.offer offer = (skedModels.offer)skedAutoMapper.instance.mapTo(skedOffer, skedModels.offer.class);
            results.add(offer);
        }
        return results;
    }

    private sked_Offer__c getOfferById(string offerId) {
        sked_Offer__c skedOffer = [SELECT Id, Name, sked_Case__c, sked_Description__c, sked_Status__c
                                   FROM sked_Offer__c
                                   WHERE Id = :offerId];
        return skedOffer;
    }

    /************************************************ Nested classes **********************************************/
    global class stopOfferModel {
        public string offerId {get;set;}
        public string reason {get;set;}
        public string notes {get;set;}
        public string startDate {get;set;}
    }
    
}