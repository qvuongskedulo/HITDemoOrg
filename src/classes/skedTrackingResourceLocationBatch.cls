global class skedTrackingResourceLocationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    protected DateTime startTime;
    protected DateTime endTime;
    protected Set<string> trackingEventTypes;
    protected Set<Id> resourceIds;
	
    global skedTrackingResourceLocationBatch(Set<Id> resourceIds, DateTime startTime, DateTime endTime) {
        this.resourceIds = resourceIds;
        this.endTime = endTime;
        this.startTime = startTime;
        
        this.trackingEventTypes = new Set<string>();
        this.trackingEventTypes.add(skedSkeduloApiData.LOCATION_HISTORY_EVENT_TYPE_ENROUTE);
        this.trackingEventTypes.add(skedSkeduloApiData.LOCATION_HISTORY_EVENT_TYPE_CHECKEDIN);
    }
    
    global List<sObject> start(Database.BatchableContext BC) {        
        List<sked__Resource__c> skedResources;
        if (this.resourceIds != NULL && !this.resourceIds.isEmpty()) {
            skedResources = [SELECT Id FROM sked__Resource__c WHERE Id IN :this.resourceIds];
        }
        else {
            skedResources = [SELECT Id FROM sked__Resource__c WHERE sked__Is_Active__c = TRUE];
        }
        return skedResources;
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Resource__c> scope) {
        Map<string, List<skedSkeduloApiData.locationHistoryItem>> mapTrackingItem = new Map<string, List<skedSkeduloApiData.locationHistoryItem>>();
        
        for (sked__Resource__c skedResource : scope) {
            skedSkeduloApiData.locationHistoryResult trackingResult = skedSkeduloApiManager.getLocationHistory(skedResource.Id, this.startTime, this.endTime);
            system.debug('#trackingResult#' + trackingResult);
            for (skedSkeduloApiData.locationHistoryItem item : trackingResult.data) {
                if (this.trackingEventTypes.contains(item.eventType)) {
                    string key = item.jobId + ':' + item.resourceId;
                    List<skedSkeduloApiData.locationHistoryItem> itemList;
                    if (mapTrackingItem.containsKey(key)) {
                        itemList = mapTrackingItem.get(key);
                    }
                    else {
                        itemList = new List<skedSkeduloApiData.locationHistoryItem>();
                        mapTrackingItem.put(key, itemList);
                    } 
                    itemList.add(item);
                }
            }
        }
        
        List<sked__Job_Allocation__c> skedAllocations = [SELECT Id, sked__UniqueKey__c,
                                                         sked_Start_Travel_GeoLocation__Latitude__s, sked_Start_Travel_GeoLocation__Longitude__s,
                                                         sked_Check_In_GeoLocation__Latitude__s, sked_Check_In_GeoLocation__Longitude__s
                                                         FROM sked__Job_Allocation__c
                                                         WHERE sked__UniqueKey__c IN :mapTrackingItem.keySet()];
        if (!skedAllocations.isEmpty()) {
            for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
                List<skedSkeduloApiData.locationHistoryItem> items = mapTrackingItem.get(skedAllocation.sked__UniqueKey__c);
                for (skedSkeduloApiData.locationHistoryItem item : items) {
                    if (item.eventType == skedSkeduloApiData.LOCATION_HISTORY_EVENT_TYPE_ENROUTE) {
                        skedAllocation.sked_Start_Travel_GeoLocation__Latitude__s = item.locationLat;
                        skedAllocation.sked_Start_Travel_GeoLocation__Longitude__s = item.locationLng;
                    }
                    else if (item.eventType == skedSkeduloApiData.LOCATION_HISTORY_EVENT_TYPE_CHECKEDIN) {
                        skedAllocation.sked_Check_In_GeoLocation__Latitude__s = item.locationLat;
                        skedAllocation.sked_Check_In_GeoLocation__Longitude__s = item.locationLng;
                    }
                }
            }
            populatedActualDistance(skedAllocations);

            update skedAllocations;
        }
    }

    private void populatedActualDistance(List<sked__Job_Allocation__c> skedAllocations) {
        List<skedModels.geometry> origins = new List<skedModels.geometry>();
        List<skedModels.geometry> destinations = new List<skedModels.geometry>();
        List<sked__Job_Allocation__c> skedAllocationsToCalculateDistance = new List<sked__Job_Allocation__c>();

        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            if (skedAllocation.sked_Start_Travel_GeoLocation__Latitude__s != NULL
                && skedAllocation.sked_Start_Travel_GeoLocation__Longitude__s != NULL
                && skedAllocation.sked_Check_In_GeoLocation__Latitude__s != NULL
                && skedAllocation.sked_Check_In_GeoLocation__Longitude__s != NULL) {
                Location startTravelLoc = Location.newInstance(skedAllocation.sked_Start_Travel_GeoLocation__Latitude__s, skedAllocation.sked_Start_Travel_GeoLocation__Longitude__s);
                Location checkedInLoc = Location.newInstance(skedAllocation.sked_Check_In_GeoLocation__Latitude__s, skedAllocation.sked_Check_In_GeoLocation__Longitude__s);
                
                skedModels.geometry origin = new skedModels.geometry(startTravelLoc);
                origins.add(origin);
                skedModels.geometry destination = new skedModels.geometry(checkedInLoc);
                destinations.add(destination);

                skedAllocationsToCalculateDistance.add(skedAllocation);
            }
        }
        if (!origins.isEmpty() && !destinations.isEmpty()) {
            skedTravelTimeService travelTimeService = new skedTravelTimeService(origins, destinations);

            for (sked__Job_Allocation__c skedAllocation : skedAllocationsToCalculateDistance) {
                skedModels.journey journey = travelTimeService.getJourney(skedAllocation.sked_Start_Travel_GeoLocation__Latitude__s, 
                                                                          skedAllocation.sked_Start_Travel_GeoLocation__Longitude__s,
                                                                          skedAllocation.sked_Check_In_GeoLocation__Latitude__s,
                                                                          skedAllocation.sked_Check_In_GeoLocation__Longitude__s);
                if (journey != NULL && journey.distance != NULL) {
                    skedAllocation.sked_Actual_Distance__c = journey.distance;
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {}   
    
}