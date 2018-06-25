public class skedJobOffersController {
    
    public static final String MSG_ACCEPT_OFFER = 'Thanks for accepting this Job. You are now an allocated Care Provider! Please click Close.';
    public static final String MSG_DECLINE_OFFER = 'Thanks for declining the Job. You will be removed from the offer list. Please click Close.';
    public static final String MSG_OFFER_NOT_AVAILABLE = 'Thanks for accepting this offer. Unfortunately, it has been allocated or is no longer available. The offer will be removed from your list.';
    
    @remoteAction
    public static skedRemoteResultModel fetchJobOffers(string resourceId) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            List<sked_Job_Offer__c> skedJobOffers = [SELECT Id, sked_Job__c, sked_Status__c, sked_Job__r.Id, sked_Job__r.Name, sked_Job__r.sked__Job_Status__c, 
                                                     sked_Job__r.sked__Type__c, sked_Job__r.sked__Start__c, sked_Job__r.sked__Finish__c,
                                                     sked_Job__r.sked__Address__c, sked_Job__r.sked__Description__c, sked_Job__r.sked__Contact__c,
                                                     sked_Job__r.sked__Contact__r.Name, sked_Job__r.sked__Timezone__c
                                                     FROM sked_Job_Offer__c
                                                     WHERE sked_Resource__c = :resourceId
                                                     AND sked_Status__c = :skedConstants.JOB_OFFER_STATUS_OFFERED];
            List<skedModels.jobOffer> jobOffers = new List<skedModels.jobOffer>();
            for (sked_Job_Offer__c skedJobOffer : skedJobOffers) {
                skedModels.jobOffer jobOffer = new skedModels.jobOffer();
                jobOffer.id = skedJobOffer.Id;
                jobOffer.jobId = skedJobOffer.sked_Job__c;
                jobOffer.status = skedJobOffer.sked_Status__c;
                
                skedAutoMapper.instance.setTimezoneSidId(skedJobOffer.sked_Job__r.sked__Timezone__c);
                jobOffer.job = (skedModels.job)skedAutoMapper.instance.mapTo(skedJobOffer.sked_Job__r, skedModels.job.class);
                jobOffers.add(jobOffer);
            }
            result.data = jobOffers;
        } 
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction 
    public static skedRemoteResultModel updateJobOfferStatus(string offerId, string status) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            sked_Job_Offer__c skedJobOffer = [SELECT Id, sked_Status__c 
                                              FROM sked_Job_Offer__c
                                              WHERE Id = :offerId];
            if (status.equalsIgnoreCase(skedJobOffer.sked_Status__c) || (skedJobOffer.sked_Status__c == skedConstants.JOB_OFFER_STATUS_CANCELLED)) {
                result.message = skedJobOffersController.MSG_OFFER_NOT_AVAILABLE;
            }
            else if (status == skedConstants.JOB_OFFER_STATUS_ACCEPTED || status == skedConstants.JOB_OFFER_STATUS_DECLINED) {
                skedJobOffer.sked_Status__c = status;
                update skedJobOffer;
                
                if (status == skedConstants.JOB_OFFER_STATUS_ACCEPTED) {
                    result.message = skedJobOffersController.MSG_ACCEPT_OFFER;
                }
                else if (status == skedConstants.JOB_OFFER_STATUS_DECLINED) {
                    result.message = skedJobOffersController.MSG_DECLINE_OFFER;
                }
            }
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    public static skedRemoteResultModel fetchResource(String userId) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            List<sked__Resource__c> skedResources = [SELECT Id, Name, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c
                                                     FROM sked__Resource__c
                                                     WHERE sked__User__c = :userId];
            if (!skedResources.isEmpty()) {
                sked__Resource__c skedResource = skedResources.get(0);
                result.data = (skedModels.resource)skedAutoMapper.instance.mapTo(skedResource, skedModels.resource.class);
            }
        } 
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
}