global class skedPacController {

    /********************************************** CLIENT AVAILABILITY *********************************************/
    @remoteAction
    global static skedRemoteResultModel getConfigData(configDataQueryModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            Account patientAccount = [SELECT Id, Name,
                                      (SELECT Id, Name
                                       FROM HealthCloudGA__Patients__r)
                                      FROM Account
                                      WHERE Id = :model.recId];
            configDataModel configData = new configDataModel();
            configData.gridSettings = skedSetting.instance.PAC;
            configData.colorMap = skedSetting.instance.PAC.mapShiftTypeSetting;
            configData.holidays = skedCommonService.getHolidays();
            configData.serviceLocations = skedUtils.getServiceLocations(patientAccount.Id);
            configData.tags = skedUtils.getTags();
            configData.regions = skedUtils.getRegions(null);
            configData.cancellationReasons = skedUtils.getPickListValues('sked__Job__c', 'sked_Cancellation_Reason__c');
            configData.cases = skedCommonService.getPatientCases(model.recId);
            configData.contacts = skedCommonService.getAccountContacts(model.recId);

            configData.patient = new skedModels.patient();
            configData.patient.id = patientAccount.Id;
            configData.patient.name = patientAccount.Name;
            
            result.data = configData;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel getClientAvailability(clientAvailabilityQueryModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            string timezoneSidId = skedUtils.getRegionTimezoneSidId(model.regionId);
            skedAutoMapper.instance.setTimezoneSidId(timezoneSidId);

            Date startDate = skedDateTimeUtils.getDateFromIsoString(model.startDate);
            Date endDate = skedDateTimeUtils.getDateFromIsoString(model.endDate);
            DateTime startTime = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
            DateTime endTime = skedDateTimeUtils.getEndOfDate(endDate, timezoneSidId);

            clientAvailabilityQueryResultModel data = new clientAvailabilityQueryResultModel();
            data.today = system.now().format(skedDateTimeUtils.DATE_ISO_FORMAT, timezoneSidId);
            data.timezone = startTime.format('z', timezoneSidId);

            if (model.objectTypes.contains('clientAvailability')) {
                List<sked_Client_Availability__c> skedClientAvailabilities = skedClientAvailabilityService.getClientAvailability(model.patientId, startTime, endTime);
                List<skedModels.clientAvailability> clientAvailabilities = new List<skedModels.clientAvailability>();

                for (sked_Client_Availability__c skedClientAvailability : skedClientAvailabilities) {
                    skedModels.clientAvailability clientAvailability = (skedModels.clientAvailability)skedAutoMapper.instance.mapTo(skedClientAvailability, skedModels.clientAvailability.class);
                    clientAvailabilities.add(clientAvailability);
                }
                data.availabilities = clientAvailabilities;
            }

            if (model.objectTypes.contains('job')) {
                skedJobService.jobQueryModel jobQuery = new skedJobService.jobQueryModel();
                jobQuery.patientId = model.patientId;
                jobQuery.startTime = startTime;
                jobQuery.startTime = startTime;
                jobQuery.endTime = endTime;
                List<sked__Job__c> skedJobs = skedJobService.getJobs(jobQuery);
                List<skedModels.job> jobs = new List<skedModels.job>();

                for (sked__Job__c skedJob : skedJobs) {
                    skedModels.job job = (skedModels.job)skedAutoMapper.instance.mapTo(skedJob, skedModels.job.class);
                    job.loadJobTags(skedJob.sked__JobTags__r);
                    job.loadJobAllocations(skedJob.sked__Job_Allocations__r);
                    jobs.add(job);
                }
                data.events = jobs;
            }
            
            result.data = data;
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel saveClientAvailability(clientAvailabilitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            saveModel.event.timezoneSidId = skedUtils.getRegionTimezoneSidId(saveModel.event.regionId);
            skedClientAvailabilityService service = new skedClientAvailabilityService();
            skedEventServiceBase.saveResult saveResult = service.saveRecord(saveModel.event, saveModel.recurringOptions);
            if (saveResult.success == false) {
                result.data = saveResult.returnedData;
            }
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel handleSaveConflicts(handleConflictModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedClientAvailabilityService service = new skedClientAvailabilityService();
            string timezoneSidId = skedUtils.getRegionTimezoneSidId(model.regionId);

            List<sked_Client_Availability__c> newRecords = new List<sked_Client_Availability__c>();
            List<sked_Client_Availability__c> recordsToDelete = new List<sked_Client_Availability__c>();

            for (skedClientAvailabilityService.conflictModel conflict : model.conflicts) {
                conflict.record.timezoneSidId = timezoneSidId;
                if (conflict.items == null || conflict.items.isEmpty()) {
                    sked_Client_Availability__c newRecord = (sked_Client_Availability__c)service.mapToSObject(conflict.record);
                    newRecords.add(newRecord);
                    continue;
                }
                boolean isCancelled = false;
                for (skedClientAvailabilityService.conflictItemModel item : conflict.items) {
                    if (item.action == 'cancel') {
                        isCancelled = true;
                        break;
                    }
                }
                if (isCancelled == true) {
                    continue;
                }

                sked_Client_Availability__c newRecord = (sked_Client_Availability__c)service.mapToSObject(conflict.record);
                for (skedClientAvailabilityService.conflictItemModel item : conflict.items) {
                    if (item.action == 'overwrite') {
                        sked_Client_Availability__c deletedRecord = new sked_Client_Availability__c(
                            Id = item.conflictRecord.id
                        );
                        recordsToDelete.add(deletedRecord);
                    }
                    else if (item.action == 'merge') {
                        item.conflictRecord.timezoneSidId = timezoneSidId;
                        sked_Client_Availability__c mergedRecord = (sked_Client_Availability__c)service.mapToSObject(item.conflictRecord);
                        if (mergedRecord.sked_Start__c < newRecord.sked_Start__c) {
                            newRecord.sked_Start__c = mergedRecord.sked_Start__c;
                        }
                        if (mergedRecord.sked_Finish__c > newRecord.sked_Finish__c) {
                            newRecord.sked_Finish__c = mergedRecord.sked_Finish__c;
                        }
                        if (string.isBlank(newRecord.Id)) {
                            newRecord.Id = mergedRecord.Id;
                        }
                        else {
                            sked_Client_Availability__c deletedRecord = new sked_Client_Availability__c(
                                Id = item.conflictRecord.id
                            );
                            recordsToDelete.add(deletedRecord);
                        }
                    }
                }
                newRecords.add(newRecord);
            }
            if (!newRecords.isEmpty()) {
                upsert newRecords;
            }
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }
    
    @remoteAction
    global static skedRemoteResultModel deleteClientAvailability(clientAvailabilitySaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavePoint();
        try {
            saveModel.event.timezoneSidId = skedUtils.getRegionTimezoneSidId(saveModel.event.regionId);
            skedClientAvailabilityService service = new skedClientAvailabilityService();
            service.deleteRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    /*********************************************************** Nested classes ***********************************************************/
    global class configDataQueryModel {
        public string recId {get;set;}
    }

    global class configDataModel {
        public List<string> cancellationReasons {get;set;}
        public skedModels.patient patient {get;set;}
        public List<skedModels.contact> contacts {get;set;}
        public skedSetting.skedPacSetting gridSettings {get;set;}
        public List<skedModels.caseModel> cases {get;set;}
        public List<skedModels.holiday> holidays {get;set;}
        public List<skedModels.region> regions {get;set;}
        public List<skedModels.tag> tags {get;set;}
        public List<skedModels.serviceLocation> serviceLocations {get;set;}
        public Map<string, skedModels.shiftTypeSetting> colorMap {get;set;}
    }
    
    global class clientAvailabilitySaveModel {
        public skedModels.clientAvailability event {get;set;}
        public skedRecurringFactory.recurringOption recurringOptions {get;set;}
    }
    
    global class clientAvailabilityQueryModel {
        public string regionId {get;set;}
        public string patientId {get;set;}
        public string caseId {get;set;}
        public string startDate {get;set;}
        public string endDate {get;set;}
        public List<string> objectTypes {get;set;}
    }

    global class clientAvailabilityQueryResultModel {
        public string today {get;set;}
        public string timezone {get;set;}
        public List<skedModels.clientAvailability> availabilities {get;set;}
        public List<skedModels.event> events {get;set;}
    }
    
    global class handleConflictModel {
        public string regionId {get;set;}
        public List<skedClientAvailabilityService.conflictModel> conflicts {get;set;}
    }

    /********************************************** APPOINTMENT *********************************************/
    @remoteAction
    global static skedRemoteResultModel getExceptionLogs(clientAvailabilityQueryModel model) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        try {
            result.data = skedExceptionLogService.getCaseExceptionLogs(model.caseId);
        }
        catch (Exception ex) {
            result.getError(ex);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveJob(jobSaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedModels.job job = (skedModels.job)saveModel.event;
            job.timezoneSidId = skedUtils.getRegionTimezoneSidId(job.regionId);
            job.eventType = skedConstants.JOB_TYPE_TREATMENT;
            if (string.isBlank(job.id)) {
                job.jobStatus = skedConstants.JOB_STATUS_PENDING_ALLOCATION;
            }

            skedJobService service = new skedJobService();
            service.saveRecord(saveModel.event, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel cancelJob(jobSaveModel saveModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedModels.job job = (skedModels.job)saveModel.event;
            job.timezoneSidId = skedUtils.getRegionTimezoneSidId(job.regionId);
            job.jobStatus = skedConstants.JOB_STATUS_CANCELLED;

            skedJobService service = new skedJobService();
            service.saveRecord(job, saveModel.recurringOptions);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel getScheduledAllocation(skedModels.job eventModel) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            skedJobService.jobQueryModel jobQueryModel = new skedJobService.jobQueryModel();
            jobQueryModel.caseId = eventModel.caseId;
            List<sked__Job__c> skedJobs = skedJobService.getJobs(jobQueryModel);
            sked__Job__c firstSkedJob = skedJobs.get(0);
            eventModel.timezoneSidId = firstSkedJob.sked__Timezone__c;
            skedAutoMapper.instance.setTimezoneSidId(eventModel.timezoneSidId);
            List<skedModels.job> scheduledJobs = new List<skedModels.job>();
            Set<Id> excludedJobIds = new Set<Id>();

            for (sked__Job__c skedJob : skedJobs) {
                skedModels.job job = (skedModels.job)skedAutoMapper.instance.mapTo(skedJob, skedModels.job.class);
                job.start = skedJob.sked__Start__c;
                job.finish = skedJob.sked__Finish__c;
                if (skedJob.sked__JobTags__r != null && !skedJob.sked__JobTags__r.isEmpty()) {
                    job.loadJobTags(skedJob.sked__JobTags__r);
                }
                if (skedJob.sked__Job_Allocations__r != null && !skedJob.sked__Job_Allocations__r.isEmpty()) {
                    job.loadJobAllocations(skedJob.sked__Job_Allocations__r);
                }
                scheduledJobs.add(job);
                excludedJobIds.add(skedJob.Id);
            }
            Set<Id> regionIds = new Set<Id>();
            regionIds.add(firstSkedJob.sked__Region__c);

            Set<Id> resourceIds = skedUtils.getActiveResourcesByTags(null, regionIds);

            skedAvailatorParams params = new skedAvailatorParams();
            params.timezoneSidId = eventModel.timezoneSidId;
            params.inputJobs = scheduledJobs;
            params.resourceIds = resourceIds;
            params.excludedJobIds = excludedJobIds;

            skedAllocationService allocationService = new skedAllocationService();
            result.data = allocationService.getAllocationData(params);
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    @remoteAction
    global static skedRemoteResultModel saveAllocations(List<skedModels.job> jobs, boolean notifyResourceOnSave) {
        skedRemoteResultModel result = new skedRemoteResultModel();
        SavePoint sp = Database.setSavepoint();
        try {
            List<sked__Job_Allocation__c> skedAllocsToInsert = new List<sked__Job_Allocation__c>();
            List<sked__Job_Allocation__c> skedAllocsToUpdate = new List<sked__Job_Allocation__c>();

            Map<Id, skedModels.job> mapJobModel = new Map<Id, skedModels.job>();
            for (skedModels.job job : jobs) {
                mapJobModel.put(job.id, job);
                for (skedModels.jobAllocation allocation : job.allocations) {
                    if (string.isBlank(allocation.action)) {
                        continue;
                    }
                    if (allocation.action == 'create') {
                        sked__Job_Allocation__c skedAlloc = new sked__Job_Allocation__c(
                            sked__Job__c = allocation.jobId,
                            sked__Resource__c = allocation.resourceId,
                            sked__Estimated_Travel_Time__c = allocation.travelTimeFrom,
                            sked_Estimated_Distance__c = allocation.travelDistanceFrom,
                            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
                        );
                        skedAllocsToInsert.add(skedAlloc);
                    }
                    else if (allocation.action == 'update') {
                        //sked__Job_Allocation__c skedAlloc = new sked__Job_Allocation__c(
                        //   Id = allocation.id
                        //);
                        //skedAllocsToUpdate.add(skedAlloc);
                    }
                    else if (allocation.action == 'delete') {
                        sked__Job_Allocation__c skedAlloc = new sked__Job_Allocation__c(
                            Id = allocation.id,
                            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED
                        );
                        skedAllocsToUpdate.add(skedAlloc);
                    }
                }
            }

            if (!skedAllocsToInsert.isEmpty()) {
                insert skedAllocsToInsert;
            }
            if (!skedAllocsToUpdate.isEmpty()) {
                update skedAllocsToUpdate;
            }

            if (notifyResourceOnSave == true) {
                skedJobService.dispatchJobs(mapJobModel.keySet());
            }
            skedJobService.updateJobStatus(mapJobModel.keySet());
        }
        catch (Exception ex) {
            result.getError(ex);
            Database.rollback(sp);
        }
        return result;
    }

    /************************************************ Nested classes **********************************************/
    global class jobSaveModel {
        public skedModels.job event {get;set;}
        public skedRecurringFactory.recurringOption recurringOptions {get;set;}
    }
    
}