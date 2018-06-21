global class skedRacController {
    
    @remoteAction
    global static skedRemoteResultModel getConfigData() {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            configDataModel configData = new configDataModel();
            configData.racSettings = skedSetting.instance.RAC;
            configData.holidays = skedCommonService.getHolidays();
            configData.regions = skedUtils.getRegions();
            configData.timezones = skedUtils.getTimezones();
            configData.activityTypes = skedUtils.getPickListOptions('sked__Activity__c', 'sked__Type__c');
            configData.availabilityTypes = skedUtils.getPickListOptions('sked__Availability__c', 'sked__Type__c');
            configData.jobTypes = skedUtils.getPickListOptions('sked__Job__c', 'sked__Type__c');
            configData.shiftTypeSettings = skedSetting.instance.RAC.mapShiftTypeSetting.values();
            
            result.data = configData;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getResourceData(queryModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            skedAutoMapper.instance.setTimezoneSidId(model.timezoneSidId);
            initializeQueryModel(model);
            
            Map<Id, resourceModel> mapResource;
            if (string.isBlank(model.resourceId)) {
                mapResource = initializeResourceList(model);
            }
            else {
                mapResource = initializeIndividualView(model);
            }
            resourceDataModel data = new resourceDataModel();
            data.resources = mapResource.values();
            data.today = system.now().format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveAvailability(availabilitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            skedModels.availability availability = (skedModels.availability)saveModel.event;
            if (skedSetting.instance.RAC.mapShiftTypeSetting.containsKey(saveModel.event.eventType)) {
                skedModels.shiftTypeSetting setting = skedSetting.instance.RAC.mapShiftTypeSetting.get(saveModel.event.eventType);
                availability.isAvailable = setting.isAvailable;
            }
            availability.status = skedSetting.instance.RAC.autoApproveAvailability == true
                                    ? skedConstants.AVAILABILITY_STATUS_APPROVED : skedConstants.AVAILABILITY_STATUS_PENDING;

            skedAvailabilityService service = new skedAvailabilityService();
            service.saveRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveActivity(activitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            skedActivityService service = new skedActivityService();
            service.saveRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel deleteAvailability(availabilitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavePoint();
        try {
            skedAvailabilityService service = new skedAvailabilityService();
            service.deleteRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel deleteActivity(activitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavePoint();
        try {
            skedActivityService service = new skedActivityService();
            service.deleteRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel approveAvailability(string shiftId) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavePoint();
        try {
            sObject record = Id.valueOf(shiftId).getSObjectType().newSObject(shiftId);
            record.put('sked__Status__c', skedConstants.AVAILABILITY_STATUS_APPROVED);
            update record;
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getSchedule(string scheduleId) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavePoint();
        try {
            result.data = skedCommonService.getSchedule(scheduleId);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveSchedule(skedModels.schedule model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    /************************************************ Get Resource Data - Private methods ***********************************************/
    private static void initializeQueryModel(queryModel model) {
        Date startDate = skedDateTimeUtils.getDateFromIsoString(model.startDate);
        Date endDate = skedDateTimeUtils.getDateFromIsoString(model.endDate);
        
        model.startTime = skedDateTimeUtils.getStartOfDate(startDate, model.timezoneSidId);
        model.endTime = skedDateTimeUtils.getStartOfDate(endDate, model.timezoneSidId);
        model.endTime = skedDateTimeUtils.addDays(model.endTime, 1, model.timezoneSidId);
        
        model.inputDates = new Set<Date>();
        Date tempDate = startDate;
        while (tempDate <= endDate) {
            model.inputDates.add(tempDate);
            tempDate = tempDate.addDays(1);
        }
        
        model.resourceIds = new Set<Id>();
        if (!string.isBlank(model.resourceId)) {
            model.resourceIds.add(model.resourceId);
        }
        else {
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id 
                                                                                     FROM sked__Resource__c 
                                                                                     WHERE sked__Primary_Region__c IN :model.regionIds
                                                                                     AND sked__Is_Active__c = TRUE]);
            model.resourceIds = mapResource.keySet();
        }
    }

    private static Map<Id, resourceModel> initializeIndividualView(queryModel model) {
        Map<Id, resourceModel> mapResource = new Map<Id, resourceModel>();
        Set<Id> resourceIds = new Set<Id>();
        resourceIds.add(model.resourceId);

        Date startDate = skedDateTimeUtils.getDateFromIsoString(model.startDate);
        Date endDate = skedDateTimeUtils.getDateFromIsoString(model.endDate);

        skedAvailatorParams params = new skedAvailatorParams();
        params.timezoneSidId = model.timezoneSidId;
        params.startDate = startDate;
        params.endDate = endDate;
        params.resourceIds = resourceIds;
        params.inputDates = model.inputDates;

        skedRACResourceAvailability resourceAvailability = new skedRACResourceAvailability(params);
        Map<Id, skedResourceAvailabilityBase.resourceModel> mapAvailatorResource = resourceAvailability.initializeResourceList();

        Map<Id, sked__Resource__c> mapSkedResources =
                new Map<Id, sked__Resource__c>([SELECT Id, Name, sked__User__r.SmallPhotoUrl, sked__User__c, sked__Category__c, sked__Home_Address__c,
                                                sked__Primary_Region__r.Name, sked__Primary_Region__c, sked__Rating__c,
                                                sked__GeoLocation__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                                (SELECT Id, sked__Tag__c, sked__Expiry_Date__c
                                                 FROM sked__ResourceTags__r
                                                 WHERE (sked__Expiry_Date__c = NULL OR sked__Expiry_Date__c >= :model.startTime))
                                                FROM sked__Resource__c
                                                WHERE Id IN :resourceIds]);

        for (skedResourceAvailabilityBase.resourceModel availatorResource : mapAvailatorResource.values()) {
            sked__Resource__c skedResource = mapSkedResources.get(availatorResource.id);
            resourceModel resource = initializeResource(skedResource);

            for (skedModels.event availatorEvent : availatorResource.events) {
                if (availatorEvent.objectType == 'non-working') {
                    availatorEvent.objectType = 'availability';
                    availatorEvent.eventType = 'non-working';     
                    availatorEvent.startDate = availatorEvent.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                    availatorEvent.startTime = integer.valueOf(availatorEvent.start.format('Hmm', model.timezoneSidId));
                    availatorEvent.endDate = availatorEvent.finish.format(skedDateTimeUtils.DATE_ISO_FORMAT, model.timezoneSidId);
                    availatorEvent.endTime = integer.valueOf(availatorEvent.finish.format('Hmm', model.timezoneSidId));  
                }    
                if (availatorEvent.objectType == 'availability') {
                    resource.availability.add(availatorEvent);
                }
                else {
                    resource.events.add(availatorEvent);   
                }
            }
            mapResource.put(resource.id, resource);
        }
        return mapResource;
    }
    
    private static Map<Id, resourceModel> initializeResourceList(queryModel model) {
        Map<Id, resourceModel> mapResource = new Map<Id, resourceModel>();
        
        for (sked__Resource__c skedResource : [SELECT Id, Name, sked__User__r.SmallPhotoUrl, sked__User__c, sked__Category__c, sked__Home_Address__c,
                                               sked__Primary_Region__r.Name, sked__Primary_Region__c, sked__Rating__c,
                                               sked__GeoLocation__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                               
                                               (SELECT Id, sked__Tag__c, sked__Expiry_Date__c
                                                FROM sked__ResourceTags__r
                                                WHERE (sked__Expiry_Date__c = NULL OR sked__Expiry_Date__c >= :model.startTime)),
                                               
                                               (SELECT Id, sked__Job__c, sked__Job__r.Id, sked__Job__r.Name, sked__Job__r.sked__Start__c, 
                                                sked__Job__r.sked__Finish__c, sked__Job__r.sked__Type__c,
                                                sked__Job__r.sked__GeoLocation__c, sked__Job__r.sked__Address__c
                                                FROM sked__Job_Allocations__r
                                                WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED 
                                                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                AND sked__Job__r.sked__Start__c < :model.endTime
                                                AND sked__Job__r.sked__Finish__c > :model.startTime
                                                ORDER BY sked__Job__r.sked__Start__c ASC),
                                               
                                               (SELECT Id, sked__Start__c, sked__Finish__c, sked__Is_Available__c, sked__Type__c, sked__Status__c,
                                                sked__Notes__c, sked_Is_All_Day__c, sked_Recurring_Schedule__c
                                                FROM sked__Availabilities1__r
                                                WHERE sked__Start__c < :model.endTime AND sked__Finish__c > :model.startTime
                                                ORDER BY sked__Start__c ASC),
                                               
                                               (SELECT Id, sked__Start__c, sked__End__c, sked__GeoLocation__c, sked__Type__c, sked__Address__c,
                                                sked__Notes__c, sked_Recurring_Schedule__c
                                                FROM sked__Activities__r
                                                WHERE sked__Start__c < :model.endTime AND sked__End__c > :model.startTime
                                                ORDER BY sked__Start__c ASC)
                                               
                                               FROM sked__Resource__c
                                               WHERE Id IN :model.resourceIds
                                               ORDER BY Name ASC]) {
            resourceModel resource = initializeResource(skedResource);
            mapResource.put(resource.Id, resource);
                                                   
            loadResourceEvents(resource, skedResource, model);
        }
        
        return mapResource;
    }
    
    private static resourceModel initializeResource(sked__Resource__c skedResource) {
        resourceModel resource = (resourceModel)skedAutoMapper.instance.mapTo(skedResource, resourceModel.class);
        resource.geoLocation = skedResource.sked__GeoLocation__c;
        if (skedResource.sked__User__r != NULL) {
            resource.photoUrl = skedResource.sked__User__r.SmallPhotoUrl;
        }

        resource.tags = new List<skedModels.tag>();
        resource.tagIds = new Set<Id>();
        for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
            resource.tagIds.add(resourceTag.sked__Tag__c);
            
            skedModels.tag tagItem = new skedModels.tag();
            tagItem.id = resourceTag.sked__Tag__c;
            tagItem.expiryTime = resourceTag.sked__Expiry_Date__c;
            resource.tags.add(tagItem);
        }
        resource.availability = new List<skedModels.event>();
        resource.events = new List<skedModels.event>();
        return resource;
    }
    
    private static void loadResourceEvents(resourceModel resource, sked__Resource__c skedResource, queryModel model) {
        for (sked__Availability__c skedAvailability : skedResource.sked__Availabilities1__r) {
            skedModels.availability availability = (skedModels.availability)skedAutoMapper.instance.mapTo(skedAvailability, skedModels.availability.class);
            resource.availability.add(availability);
        }
        
        for (sked__Job_Allocation__c skedAllocation : skedResource.sked__Job_Allocations__r) {
            skedModels.job job = (skedModels.job)skedAutoMapper.instance.mapTo(skedAllocation.sked__Job__r, skedModels.job.class);
            resource.events.add(job);
        }
        
        for (sked__Activity__c skedActivity : skedResource.sked__Activities__r) {
            skedModels.activity activity = (skedModels.activity)skedAutoMapper.instance.mapTo(skedActivity, skedModels.activity.class);
            resource.events.add(activity);
        }
        
        resource.events.sort();
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class configDataModel {
        public List<skedModels.holiday> holidays {get;set;}
        public List<skedModels.selectOption> activityTypes {get;set;}
        public List<skedModels.selectOption> jobTypes {get;set;}
        public List<skedModels.selectOption> availabilityTypes {get;set;}
        public skedSetting.skedRacSetting racSettings {get;set;}
        public List<skedModels.region> regions {get;set;}
        public List<skedModels.shiftTypeSetting> shiftTypeSettings {get;set;}
        public List<skedModels.selectOption> timezones {get;set;}
    }
    
    global class queryModel {
        public List<string> regionIds {get;set;}
        public string resourceId {get;set;}
        public string startDate {get;set;}
        public string endDate {get;set;}
        public string timezoneSidId {get;set;}
        public List<string> tagIds {get;set;}
        
        public transient DateTime startTime {get;set;}
        public transient DateTime endTime {get;set;}
        public transient Set<Date> inputDates {get;set;}
        public transient Set<Id> resourceIds {get;set;}
    }

    global class resourceDataModel {
        public List<skedModels.resource> resources {get;set;}
        public string today {get;set;}
    }
    
    global class availabilitySaveModel {
        public skedModels.availability event {get;set;}
        public skedRecurringFactory.recurringOption recurringOptions {get;set;}
    }
    
    global class activitySaveModel {
        public skedModels.activity event {get;set;}
        public skedRecurringFactory.recurringOption recurringOptions {get;set;}
    }
    
    global class resourceModel extends skedModels.resource {
        public List<skedModels.event> availability {get;set;}
        public List<skedModels.event> events {get;set;}
    }
    
}