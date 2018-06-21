global virtual class skedResourceAvailabilityBase {

    protected skedAvailatorParams params {get;set;}

    public skedResourceAvailabilityBase(skedAvailatorParams params) {
        initialize(params);
    }
    
    public Map<Id, resourceModel> initializeResourceList() {
        Map<Id, resourceModel> mapResource = loadWorkingTime();

        for (sked__Resource__c skedResource : [SELECT Id, Name, sked__User__r.SmallPhotoUrl, sked__User__c, sked__Category__c, sked__Home_Address__c,
                                               sked__Primary_Region__r.Name, sked__Primary_Region__c, sked__Rating__c,
                                               sked__GeoLocation__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s, 
                                               
                                               (SELECT Id, sked__Whitelisted__c, sked__Blacklisted__c
                                                FROM sked__Account_Resource_Scores__r
                                                WHERE sked__Account__c = :this.params.accountId),
                                               
                                               (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Expiry_Date__c
                                                FROM sked__ResourceTags__r
                                                WHERE (sked__Expiry_Date__c = NULL OR sked__Expiry_Date__c >= :this.params.startTime)),
                                               
                                               (SELECT Id, sked__Job__c, sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                                                sked__Job__r.sked__GeoLocation__c, sked__Job__r.sked__Address__c, sked__Job__r.sked__Type__c
                                                FROM sked__Job_Allocations__r
                                                WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED 
                                                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                AND DAY_ONLY(sked__Job__r.sked__Start__c) IN :this.params.inputDates
                                                AND sked__Job__c NOT IN :this.params.excludedJobIds
                                                ORDER BY sked__Job__r.sked__Start__c ASC),
                                               
                                               (SELECT Id, sked__Start__c, sked__Finish__c, sked__Is_Available__c, sked__Type__c, sked__Status__c,
                                                sked__Notes__c, sked_Is_All_Day__c, sked_Recurring_Schedule__c
                                                FROM sked__Availabilities1__r
                                                WHERE sked__Start__c < :this.params.endTime AND sked__Finish__c > :this.params.startTime
                                                AND sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                                ORDER BY sked__Start__c ASC),
                                               
                                               (SELECT Id, sked__Start__c, sked__End__c, sked__GeoLocation__c, sked__Type__c, sked__Address__c,
                                                sked__Notes__c, sked_Recurring_Schedule__c
                                                FROM sked__Activities__r
                                                WHERE DAY_ONLY(sked__Start__c) IN :this.params.inputDates
                                                ORDER BY sked__Start__c ASC)
                                               
                                               FROM sked__Resource__c
                                               WHERE Id IN :this.params.resourceIds]) {
            resourceModel resource; 
            if (mapResource.containsKey(skedResource.Id)) {
                resource = mapResource.get(skedResource.Id);
            }
            else {
                resource = new resourceModel();
                resource.id = skedResource.Id;
            }
            initializeResource(skedResource, resource);

            if (resource.accountResourceScore != NULL && resource.accountResourceScore.blacklisted == true) {
                continue;
            }
            if (!mapResource.containsKey(skedResource.Id)) {
                for (Date jobDate : this.params.inputDates) {
                    dateslotModel dateslot = new dateslotModel();
                    dateslot.start = skedDateTimeUtils.getStartOfDate(jobDate, this.params.timezoneSidId);
                    dateslot.finish = skedDateTimeUtils.addDays(dateslot.start, 1, this.params.timezoneSidId);
                    dateslot.addEvent(dateslot.start, dateslot.finish, 'non-working', false);

                    string key = dateslot.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.params.timezoneSidId);
                    resource.mapDateslot.put(key, dateslot);
                }
                mapResource.put(resource.id, resource);
            }
            loadResourceEvents(skedResource, resource, this.params.timezoneSidId);

            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                resource.events.addAll(dateslot.events);
            }
        }

        initializeOtherResourceData(mapResource);
        
        return mapResource;
    }

    protected virtual void initializeOtherResourceData(Map<Id, resourceModel> mapResource) {}
    /**********************************************************Private methods********************************************************************/
	protected void initialize(skedAvailatorParams inputParams) {
        if (inputParams.inputDates == null || inputParams.inputDates.isEmpty()) {
            if (inputParams.inputJobs != null && !inputParams.inputJobs.isEmpty()) {
                Set<Date> inputDates = new Set<Date>();
                Date startDate, endDate;
                for (skedModels.job job : inputParams.inputJobs) {
                    Date jobDate = skedDateTimeUtils.getDateFromIsoString(job.startDate);
                    inputDates.add(jobDate);
                    if (startDate == null || startDate > jobDate) {
                        startDate = jobDate;
                    }
                    if (endDate == null || endDate < jobDate) {
                        endDate = jobDate;
                    }
                }
                inputParams.startDate = startDate;
                inputParams.endDate = endDate;
                inputParams.inputDates = inputDates;
            }
        }

        this.params = inputParams;

        this.params.startTime = skedDateTimeUtils.getStartOfDate(this.params.startDate, this.params.timezoneSidId);
        this.params.endTime = skedDateTimeUtils.getStartOfDate(this.params.endDate, this.params.timezoneSidId);
        this.params.endTime = skedDateTimeUtils.addDays(this.params.endTime, 1, this.params.timezoneSidId);
    }

    protected Map<Id, resourceModel> loadWorkingTime() {
        Map<Id, resourceModel> mapResource = new Map<Id, resourceModel>();
        List<sked__Availability_Template_Resource__c> templateResourceList = [SELECT sked__Resource__c, sked__Availability_Template__c
                                                                              FROM sked__Availability_Template_Resource__c
                                                                              WHERE sked__Resource__c IN :this.params.resourceIds];
        Map<Id, Set<Id>> map_TemplateId_ResourceIds = new Map<Id, Set<Id>>();
        for (sked__Availability_Template_Resource__c atr : templateResourceList) {
            Set<Id> resourceIds;
            if (map_TemplateId_ResourceIds.containsKey(atr.sked__Availability_Template__c)) {
                resourceIds = map_TemplateId_ResourceIds.get(atr.sked__Availability_Template__c);
            }
            else {
                resourceIds = new Set<Id>();
                map_TemplateId_ResourceIds.put(atr.sked__Availability_Template__c, resourceIds);
            }
            resourceIds.add(atr.sked__Resource__c);
        }

        Map<Id, sked__Availability_Template__c> mapTemplate 
            = new Map<Id, sked__Availability_Template__c>([SELECT Id, 
                                                           (SELECT Id, sked__Finish_Time__c, sked__Is_Available__c, sked__Start_Time__c, sked__Weekday__c 
                                                            FROM sked__Availability_Template_Entries__r) 
                                                           FROM sked__Availability_Template__c 
                                                           WHERE Id IN :map_TemplateId_ResourceIds.keySet()]);
        for (sked__Availability_Template__c skedTemplate : mapTemplate.values()) {
            Set<Id> resourceIds = map_TemplateId_ResourceIds.get(skedTemplate.Id);
            Map<string, sked__Availability_Template_Entry__c> mapEntry = new Map<string, sked__Availability_Template_Entry__c>();
            for (sked__Availability_Template_Entry__c entry : skedTemplate.sked__Availability_Template_Entries__r) {
                mapEntry.put(entry.sked__Weekday__c, entry);
            }
            resourceModel sourceResource;
            for (Id resourceId : resourceIds) {
                resourceModel resource = new resourceModel();
                resource.id = resourceId;

                if (sourceResource == null) {
                    for (Date jobDate : this.params.inputDates) {
                        dateslotModel dateslot = new dateslotModel();
                        dateslot.start = skedDateTimeUtils.getStartOfDate(jobDate, this.params.timezoneSidId);
                        dateslot.finish = skedDateTimeUtils.addDays(dateslot.start, 1, this.params.timezoneSidId);
                        dateslot.addEvent(dateslot.start, dateslot.finish, 'non-working', false);

                        string key = dateslot.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.params.timezoneSidId);
                        resource.mapDateslot.put(key, dateslot);

                        string weekday = dateslot.start.format('EEE', this.params.timezoneSidId).toUpperCase();
                        
                        if (mapEntry.containsKey(weekday)) {
                            sked__Availability_Template_Entry__c entry = mapEntry.get(weekday);
                            integer startWorkingInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.sked__Start_Time__c);
                            integer endWorkingInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.sked__Finish_Time__c);

                            DateTime startWorkingTime = skedDateTimeUtils.addMinutes(dateslot.start, startWorkingInMinutes, this.params.timezoneSidId);
                            DateTime endWorkingTime = skedDateTimeUtils.addMinutes(dateslot.start, endWorkingInMinutes, this.params.timezoneSidId);

                            dateslot.addEvent(startWorkingTime, endWorkingTime, null, true);
                        }
                    }
                    sourceResource = resource;
                }
                else {
                    for (string key : sourceResource.mapDateslot.keySet()) {
                        dateslotModel dateslot = sourceResource.mapDateslot.get(key);
                        dateslotModel cloneItem = dateslot.deepClone();
                        resource.mapDateslot.put(key, cloneItem);
                    }
                }
                mapResource.put(resourceId, resource);
            }
        }
        return mapResource;
    }

    protected void initializeResource(sked__Resource__c skedResource, resourceModel resource) {
        resource.name = skedResource.Name;
        resource.category = skedResource.sked__Category__c;
        resource.regionName = skedResource.sked__Primary_Region__r.Name;
        if (skedResource.sked__User__c != NULL) {
            resource.userId = skedResource.sked__User__c;
            resource.photoUrl = skedResource.sked__User__r.SmallPhotoUrl;
        }
        resource.geoLocation = skedResource.sked__GeoLocation__c;
        resource.address = new skedModels.address();
        resource.address.geometry = new skedModels.geometry(skedResource.sked__GeoLocation__c);

        Set<Id> tagSet;
        if (this.params.isUsingSameTagSet) {
            tagSet = this.params.tagIds;
        }
        resource.loadResourceTags(skedResource.sked__ResourceTags__r, tagSet);

        if (this.params.enableAccountResourceScore == TRUE) {
            resource.loadResourceScore(skedResource.sked__Account_Resource_Scores__r);
        }
    }

    protected virtual void loadResourceEvents(sked__Resource__c skedResource, resourceModel resource, string timezoneSidId) {
        for (sked__Availability__c availableBlock : skedResource.sked__Availabilities1__r) {
            if (availableBlock.sked__Is_Available__c == FALSE) {
                continue;
            }
            DateTime availableStart = availableBlock.sked__Start__c;
            DateTime availableEnd = availableBlock.sked__Finish__c;

            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                if (dateslot.finish <= availableStart || dateslot.start >= availableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = availableStart < dateslot.start ? dateslot.start : availableStart; 
                    DateTime tempEnd = availableEnd > dateslot.finish ? dateslot.finish : availableEnd;
                    dateslot.addEvent(availableStart, availableEnd, null, true);
                }
            }
        }
        for (sked__Availability__c unavailableBlock : skedResource.sked__Availabilities1__r) {
            if (unavailableBlock.sked__Is_Available__c == TRUE) {
                continue;
            }
            DateTime unavailableStart = unavailableBlock.sked__Start__c;
            DateTime unavailableEnd = unavailableBlock.sked__Finish__c;
            
            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                if (dateslot.finish <= unavailableStart || dateslot.start >= unavailableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = unavailableStart < dateslot.start ? dateslot.start : unavailableStart; 
                    DateTime tempEnd = unavailableEnd > dateslot.finish ? dateslot.finish : unavailableEnd;
                    skedModels.availability availability = new skedModels.availability();
                    availability.objectType = 'availability';
                    availability.id = unavailableBlock.Id;
                    availability.start = tempStart;
                    availability.finish = tempEnd;
                    dateslot.events.add(availability);
                }
            }
        }
        
        for (sked__Job_Allocation__c skedAllocation : skedResource.sked__Job_Allocations__r) {
            string allocationDateString = skedAllocation.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);
            
            if (resource.mapDateslot.containsKey(allocationDateString)) {
                dateslotModel dateslot = resource.mapDateslot.get(allocationDateString);
                skedModels.jobAllocation jobAllocation = new skedModels.jobAllocation();
                jobAllocation.objectType = 'jobAllocation';
                jobAllocation.id = skedAllocation.Id;
                jobAllocation.start = skedAllocation.sked__Job__r.sked__Start__c;
                jobAllocation.finish = skedAllocation.sked__Job__r.sked__Finish__c;
                jobAllocation.geolocation = skedAllocation.sked__Job__r.sked__GeoLocation__c;
                dateslot.events.add(jobAllocation);
            }
        }
        for (sked__Activity__c skedActivity : skedResource.sked__Activities__r) {
            string activityDateString = skedActivity.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);
            if (resource.mapDateslot.containsKey(activityDateString)) {
                dateslotModel dateslot = resource.mapDateslot.get(activityDateString);
                skedModels.activity activity = new skedModels.activity();
                activity.objectType = 'activity';
                activity.id = skedActivity.Id;
                activity.start = skedActivity.sked__Start__c;
                activity.finish = skedActivity.sked__End__c;
                activity.geolocation = skedActivity.sked__GeoLocation__c;
                dateslot.events.add(activity);
            }
        }
        
        for (dateslotModel dateslot : resource.mapDateslot.values()) {
            dateslot.events.sort();
        }
    }

    /**********************************************************Nested classes********************************************************************/
    global class resourceModel extends skedModels.resource {
        public transient Map<string, dateslotModel> mapDateslot {get;set;}
        public transient List<skedModels.event> events {get; set;}

        public resourceModel() {
            this.mapDateslot = new Map<string, dateslotModel>();
            this.events = new List<skedModels.event>();
        }
    }
    
    global class dateslotModel {
        public DateTime start {get;set;}
        public DateTime finish {get;set;}
        public List<skedModels.event> events {get;set;}
        
        public dateslotModel() {
            this.events = new List<skedModels.event>();
        }

        public dateslotModel deepClone() {
            dateslotModel result = new dateslotModel();
            result.start = this.start;
            result.finish = this.finish;
            for (skedModels.event event : this.events) {
                skedModels.event cloneItem = event.clone();
                result.events.add(cloneItem);
            }
            return result;
        }
        
        public skedModels.event addEvent(DateTime startTime, DateTime endTime, string objectType, boolean isAvailable) {
            return addEvent(startTime, endTime, objectType, isAvailable, null);
        }
        
        public skedModels.event addEvent(DateTime startTime, DateTime endTime, string objectType, boolean isAvailable, string relatedId) {
            if (isAvailable == true) {
                addAvailableBlock(startTime, endTime);
            }
            else {
                skedModels.event newEvent = new skedModels.event();
                newEvent.start = startTime;
                newEvent.finish = endTime;
                newEvent.objectType = objectType;
                this.events.add(newEvent);
                return newEvent;
            }
            return null;
        }
        
        private void addAvailableBlock(DateTime startTime, DateTime endTime) {
            List<skedModels.event> newEvents = new List<skedModels.event>();
            Set<DateTime> removedEvents = new Set<DateTime>();

            for (skedModels.event eventItem : this.events) {
                if (eventItem.start < startTime && startTime < eventItem.finish) {
                    if (endTime < eventItem.finish) {
                        skedModels.event newEvent = new skedModels.event();
                        newEvent.start = endTime;
                        newEvent.finish = eventItem.finish;
                        newEvent.objectType = eventItem.objectType;
                        newEvents.add(newEvent);
                    }
                    eventItem.finish = startTime;
                }
                else if (startTime <= eventItem.start) {
                    if (endTime >= eventItem.finish) {
                        removedEvents.add(eventItem.start);
                    }
                    else if (eventItem.start < endTime && endTime < eventItem.finish) {
                        eventItem.start = endTime;
                    }
                }
            }
            
            for (integer i = this.events.size() - 1; i >= 0; i--) {
                skedModels.event eventItem = this.events.get(i);
                if (removedEvents.contains(eventItem.start)) {
                    this.events.remove(i);
                }
            }
            
            this.events.addAll(newEvents);
        }
    }
    
}