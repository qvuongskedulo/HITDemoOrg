global class skedGroupEventController {

    @remoteAction
    global static skedRemoteResultModel getConfigData() {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            configDataModel configData = new configDataModel();
            configData.regions = skedUtils.getRegions();
            configData.statuses = skedUtils.getPickListOptions('sked__Group_Event__c', 'sked__Status__c');
            configData.tags = skedUtils.getTags();

            result.data = configData;
        } catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel searchContact(skedModels.searchOption searchModel) {
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
    global static skedRemoteResultModel saveGroupEvent(skedModels.groupEvent groupEventModel) {
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
    global static skedRemoteResultModel addGroupClient(skedModels.groupAttendee groupClientModel) {
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
    global static skedRemoteResultModel removeGroupClient(skedModels.groupAttendee groupClientModel) {
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
    }

    global class jobSaveModel {
        public skedModels.job event {get;set;}
    }
}