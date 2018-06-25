global class skedBookingGridController {
	
    @remoteAction
    global static skedRemoteResultModel getConfigData(string recId) {
     	skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            configDataModel configData = new configDataModel();
            configData.jobTypes = new List<string>();
            configData.jobTypes.add(skedConstants.JOB_TYPE_INITIAL_EVALUATION);
            configData.cases = skedCommonService.getPatientCases(recId);
            configData.contacts = skedCommonService.getAccountContacts(recId);
            configData.tags = skedUtils.getTags();
            configData.regions = skedUtils.getRegions(null);
            configData.gridSettings = skedSetting.instance.BG;
            configData.cancellationReasons = skedUtils.getPickListValues('sked__Job__c', 'sked_Cancellation_Reason__c');
            
            result.data = configData;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getScheduledJobs(string accountId, string regionId) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            string timezoneSidId = skedUtils.getRegionTimezoneSidId(regionId);
            skedAutoMapper.instance.setTimezoneSidId(timezoneSidId);

            List<skedModels.job> scheduledJobs = new List<skedModels.job>();
            DateTime timeConstraint = system.now().addMinutes(15);
            List<sked__Job__c> skedJobs = [SELECT Id, Name, sked__Region__c, sked__Account__c, sked__Contact__c,
                                           sked__Type__c, sked__Address__c, sked__GeoLocation__c, sked__Description__c,
                                           sked__Start__c, sked__Finish__c,  sked__Duration__c,sked__Job_Status__c,
                                           sked__Notes_Comments__c, sked_Case__c,
                                           (SELECT sked__Tag__c, sked__Tag__r.Name, sked_Is_Excluded__c
                                            FROM sked__JobTags__r),
                                           (SELECT Id, sked__Job__c, sked__Resource__c, sked__Resource__r.Name,
                                            sked__Resource__r.sked__User__r.SmallPhotoUrl,
                                            sked_Estimated_Distance__c, sked__Estimated_Travel_Time__c
                                            FROM sked__Job_Allocations__r
                                            WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                                           FROM sked__Job__c
                                           WHERE sked__Account__c = :accountId
                                           AND sked__Type__c = :skedConstants.JOB_TYPE_INITIAL_EVALUATION
                                           AND sked__Start__c > :timeConstraint
                                           AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED];
            for (sked__Job__c skedJob : skedJobs) {
                skedModels.job job = (skedModels.job)skedAutoMapper.instance.mapTo(skedJob, skedModels.job.class);
                if (skedJob.sked__JobTags__r != null && !skedJob.sked__JobTags__r.isEmpty()) {
                    job.loadJobTags(skedJob.sked__JobTags__r);
                }
                if (skedJob.sked__Job_Allocations__r != null && !skedJob.sked__Job_Allocations__r.isEmpty()) {
                    job.loadJobAllocations(skedJob.sked__Job_Allocations__r);
                }
                scheduledJobs.add(job);
            }
            result.data = scheduledJobs;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getBookingGrid(gridQueryModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            model.timezoneSidId = skedUtils.getRegionTimezoneSidId(model.job.regionId);

            Set<Id> tagIds = new Set<Id>();
            tagIds.addAll(model.job.tagIds);

            Set<Id> regionIds = new Set<Id>();
            regionIds.add(model.job.regionId);

            model.resourceIds = skedUtils.getActiveResourcesByTags(tagIds, regionIds);
            skedGridBuilder builder = new skedGridBuilder();
            builder.config = model;
            skedGridBuilder.gridModel grid = builder.initialize();

            result.data = grid;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getAvailableResources(skedModels.job model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            model.timezoneSidId = skedUtils.getRegionTimezoneSidId(model.regionId);

            Date startDate = skedDateTimeUtils.getDateFromIsoString(model.startDate);
            integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(model.startTime);
            DateTime startDateDt = skedDateTimeUtils.getStartOfDate(startDate, model.timezoneSidId);
            model.start = skedDateTimeUtils.addMinutes(startDateDt, startTimeInMinutes, model.timezoneSidId);
            model.finish = skedDateTimeUtils.addMinutes(model.start, model.duration, model.timezoneSidId);

            List<skedModels.job> inputJobs = new List<skedModels.job>();
            inputJobs.add(model);

            Set<Id> tagIds = new Set<Id>();
            tagIds.addAll(model.tagIds);

            Set<Id> regionIds = new Set<Id>();
            regionIds.add(model.regionId);

            skedAvailatorParams params = new skedAvailatorParams();
            params.timezoneSidId = model.timezoneSidId;
            params.inputJobs = inputJobs;
            params.resourceIds = skedUtils.getActiveResourcesByTags(tagIds, regionIds);
            params.excludedJobIds = new Set<Id>();
            if (!string.isBlank(model.id)) {
                params.excludedJobIds.add(model.id);
            }

            skedAllocationService allocationService = new skedAllocationService();
            result.data = allocationService.getAllocationData(params);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveJob(skedModels.job jobModel, skedModels.jobAllocation allocationModel, boolean notifyResourceOnSave) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            jobModel.timezoneSidId = skedUtils.getRegionTimezoneSidId(jobModel.regionId);
            Id assignedResourceId;
            if (!string.isBlank(jobModel.id)) {
                List<sked__Job_Allocation__c> skedAllocations = [SELECT Id, sked__Resource__c
                                                                 FROM sked__Job_Allocation__c
                                                                 WHERE sked__Job__c = :jobModel.id
                                                                 AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
                if (!skedAllocations.isEmpty()) {
                    assignedResourceId = skedAllocations.get(0).sked__Resource__c;
                    if (assignedResourceId != allocationModel.resourceId) {
                        skedJobService.cancelJob(jobModel.id, skedConstants.JOB_CANCELLATION_REASON_RESCHEDULED);
                        jobModel.rescheduleJobId = jobModel.id;
                        jobModel.jobStatus = skedConstants.JOB_STATUS_PENDING_DISPATCH;
                        jobModel.id = null;
                    }
                }
            }
            else {
                jobModel.jobStatus = skedConstants.JOB_STATUS_PENDING_DISPATCH;
            }
            skedJobService service = new skedJobService();
            skedEventServiceBase.saveResult saveResult = service.saveRecord(jobModel);
            sked__Job__c skedJob = (sked__Job__c)saveResult.savedObjects.get(0);

            if (skedJobService.checkConcurrency(skedJob, allocationModel.resourceId)) {
                throw new skedException(skedConstants.EXCEPTION_CONCURRENCY);
            } else if (checkConcurrencyPatient(skedJob)) {
                throw new skedException(skedConstants.EXCEPTION_CONCURRENCY_PATIENT);
            }

            if (assignedResourceId == null || assignedResourceId != allocationModel.resourceId) {
                sked__Job_Allocation__c skedAlloc = new sked__Job_Allocation__c(
                    sked__Job__c = skedJob.Id,
                    sked__Resource__c = allocationModel.resourceId,
                    sked__Estimated_Travel_Time__c = allocationModel.travelTimeFrom,
                    sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH,
                    sked_Estimated_Distance__c = allocationModel.travelDistanceFrom
                );
                insert skedAlloc;
            }
            if (notifyResourceOnSave == true) {
                skedJobService.dispatchJob(skedJob.Id);
            }
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveJob(skedModels.job job, List<skedModels.jobOffer> jobOffers) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            job.timezoneSidId = skedUtils.getRegionTimezoneSidId(job.regionId);
            
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel cancelJob(skedModels.job model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            skedJobService.cancelJob(model.id, model.cancellationReason);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    /*********************************************************** Private methods ***********************************************************/
    private static boolean checkConcurrencyPatient(sked__Job__c skedJob) {
        List<sked__Job__c> skedJobs = [SELECT Id
                                       FROM sked__Job__c
                                       WHERE Id != :skedJob.Id
                                       AND sked__Account__c = :skedJob.sked__Account__c
                                       AND sked__Type__c = :skedConstants.JOB_TYPE_INITIAL_EVALUATION
                                       AND sked__Start__c < :skedJob.sked__Finish__c
                                       AND sked__Finish__c > :skedJob.sked__Start__c
                                       AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED];
        return !skedJobs.isEmpty();
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class configDataModel {
        public List<skedModels.caseModel> cases {get;set;}
        public List<string> jobTypes {get;set;}
        public List<skedModels.region> regions {get;set;}
        public List<skedModels.tag> tags {get;set;}
        public List<skedModels.contact> contacts {get;set;}
        public List<string> cancellationReasons {get;set;}
        public skedSetting.skedBookingGridSetting gridSettings {get;set;}
    }
    
    global class gridQueryModel extends skedGridBuilder.configuration {
    }

}