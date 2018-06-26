global class skedGroupEventController {

    public skedGroupEventController(ApexPages.StandardController stdController) {
    }

    @remoteAction
    global static skedRemoteResultModel getConfigData() {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            configDataModel configData = new configDataModel();
            configData.regions = skedUtils.getRegions();
            configData.statuses = skedUtils.getPickListOptions('sked__Group_Event__c', 'sked__Status__c');
            configData.tags = skedUtils.getTags();
            configData.cancellationReasons = skedUtils.getPickListValues('sked__Job__c', 'sked_Cancellation_Reason__c');

            result.data = configData;
        } catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel searchContacts(skedSearchService.searchOptionModel searchModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedSearchService searchService = new skedSearchService();
            result.data = searchService.searchContact(searchModel);
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getGroupEvent(skedModels.groupEvent groupEventModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveGroupEvent(skedModels.groupEvent groupEventModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedGroupEventService groupEventService = new skedGroupEventService();
            // Save Group Event
            groupEventService.saveRecord(groupEventModel);

            // Save Group Attendee
            for (skedModels.groupAttendee attendee : groupEventModel.attendees) {
                attendee.groupEventId = groupEventModel.Id;
            }
            saveGroupAttendees(groupEventModel.attendees);

            // Save Group Tag
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveGroupAttendees(List<skedModels.groupAttendee> groupAttendeeModels) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedGroupEventService groupEventService = new skedGroupEventService();
            result.data = groupEventService.saveRecord(groupAttendeeModels);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel removeGroupAttendee(skedModels.groupAttendee groupAttendeeModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveGroupTag(list<skedModels.groupTag> groupTagModels) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedGroupEventService groupEventService = new skedGroupEventService();
            result.data = groupEventService.saveRecord(groupTagModels);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getJobAteendee(groupEventJobModel groupEventJobModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            //skedGroupEventService groupEventService = new skedGroupEventService();
            //list<sked_Group_Tag__c> groupTags = groupEventService.saveRecord(groupTagModels)[0];
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveJob(jobSaveModel jobSaveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedModels.job job = (skedModels.job)jobSaveModel.event;
            job.timezoneSidId = skedUtils.getRegionTimezoneSidId(job.regionId);
            job.eventType = skedConstants.JOB_TYPE_GROUP_EVENT;
            if (string.isBlank(job.id)) {
                job.jobStatus = skedConstants.JOB_STATUS_PENDING_ALLOCATION;
            }

            skedJobService service = new skedJobService();
            service.saveRecord(jobSaveModel.event, NULL);
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel cancelJob(jobSaveModel jobSaveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedModels.job job = (skedModels.job)jobSaveModel.event;
            job.jobStatus = skedConstants.JOB_STATUS_CANCELLED;

            skedJobService service = new skedJobService();
            skedEventServiceBase.saveResult saveResult = service.saveRecord(job, NULL);

            Set<Id> jobIds = skedUtils.getIdsFromList(saveResult.savedObjects);
            skedJobService.cancelJobs(jobIds, job.cancellationReason);
        } 
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }


    /*********************************************************** Nested classes ***********************************************************/
    global class configDataModel {
        public List<skedModels.region> regions {get; set;}
        public List<skedModels.selectOption> statuses {get; set;}
        public List<skedModels.tag> tags {get; set;}
        public List<string> cancellationReasons {get; set;}
    }

    global class jobSaveModel {
        public skedModels.job event {get;set;}
    }

    global class groupEventJobModel extends skedModels.job {
        public string groupEventId {get;set;}
        public list<jobAttendeeModel> jobAttendees {get;set;}
    }

    global class jobAttendeeModel extends skedModels.modelBase{
        public string action {get; set;}
        public string contactId {get; set;}
    }
}