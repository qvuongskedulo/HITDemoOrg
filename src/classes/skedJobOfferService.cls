public class skedJobOfferService {
    
    public void autoCancelConflictedOffers(List<resourceUnavailabilityModel> unavailabilityList) {
        Set<Id> resourceIds = new Set<Id>();
		DateTime minDt, maxDt;
		boolean hasTermination = false;
		for (resourceUnavailabilityModel unavailability : unavailabilityList) {
			resourceIds.add(unavailability.resourceId);
			if (minDt == NULL || unavailability.startTime < minDt) {
				minDt = unavailability.startTime;
			}
			if (unavailability.endTime != NULL) {
				if (maxDt == NULL || unavailability.endTime > maxDt) {
					maxDt = unavailability.endTime;
				}
			}
			else {
				hasTermination = true;
			}
		}
		if (hasTermination) {
			maxDt = NULL;
		}
        
        List<sked_Job_Offer__c> conflictedOffers = getImpactedJobOffers(resourceIds, minDt, maxDt);
        Map<Id, List<sked_Job_Offer__c>> map_resourceId_conflictedOffers = new Map<Id, List<sked_Job_Offer__c>>();
        for (sked_Job_Offer__c conflictedItem : conflictedOffers) {
            List<sked_Job_Offer__c> resourceConflictedOffers;
            if (map_resourceId_conflictedOffers.containsKey(conflictedItem.sked_Resource__c)) {
                resourceConflictedOffers = map_resourceId_conflictedOffers.get(conflictedItem.sked_Resource__c);
            }
            else {
                resourceConflictedOffers = new List<sked_Job_Offer__c>();
                map_resourceId_conflictedOffers.put(conflictedItem.sked_Resource__c, resourceConflictedOffers);
            }
            resourceConflictedOffers.add(conflictedItem);
        }
        
        List<sked_Job_Offer__c> jobOffersToUpdate = new List<sked_Job_Offer__c>();
        for (resourceUnavailabilityModel unavailability : unavailabilityList) {
            List<sked_Job_Offer__c> resourceConflictedOffers = map_resourceId_conflictedOffers.get(unavailability.resourceId);
			for (sked_Job_Offer__c conflictedItem : resourceConflictedOffers) {
				if (conflictedItem.sked_Job__r.sked__Finish__c < unavailability.startTime) {
					continue;
				}
				if (unavailability.endTime != NULL && unavailability.endTime <= conflictedItem.sked_Job__r.sked__Start__c) {
					break;
				}
                conflictedItem.sked_Status__c = skedConstants.JOB_OFFER_STATUS_CANCELLED;
                jobOffersToUpdate.add(conflictedItem);
			}
		}
        if (!jobOffersToUpdate.isEmpty()) {
            update jobOffersToUpdate;
        }
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static List<sked_Job_Offer__c> getImpactedJobOffers(Set<Id> resourceIds, DateTime startTime, DateTime endTime) {
		List<string> fields = new List<string>();
		fields.add('Id');
		fields.add('sked_Job__c');
		fields.add('sked_Resource__c');
		fields.add('sked_Job__r.sked__Start__c');
		fields.add('sked_Job__r.sked__Finish__c');

		List<string> conditions = new List<string>();
		conditions.add('sked_Resource__c IN :resourceIds');
		if (endTime != NULL) {
			conditions.add('sked_Job__r.sked__Start__c < :endTime');
			conditions.add('sked_Job__r.sked__Finish__c > :startTime');
		}
		else {
			conditions.add('sked_Job__r.sked__Start__c >= :startTime');			
		}
		List<string> activeJobOfferStatuses = new List<string>();
		activeJobOfferStatuses.add(skedConstants.JOB_OFFER_STATUS_OFFERED);

		conditions.add('sked_Status__c IN :activeJobOfferStatuses');

		string queryString = 'SELECT ' + string.join(fields, ', ') 
							+ ' FROM sked_Job_Offer__c'
							+ ' WHERE ' + string.join(conditions, ' AND ')
							+ ' ORDER BY sked_Job__r.sked__Start__c ASC';
 	    return (List<sked_Job_Offer__c>)Database.query(queryString);
	}
    
    /*********************************************************** Nested classes ***********************************************************/
	public class resourceUnavailabilityModel {
		public string resourceId {get;set;}
		public DateTime startTime {get;set;}
		public DateTime endTime {get;set;}
	}
    
}