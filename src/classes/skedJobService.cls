global class skedJobService extends skedEventServiceBase {

    /*********************************************************** Protected ***********************************************************/
    protected override void initialize() {
        this.sObjectApiName = 'sked__Job__c';
        this.startFieldApiName = 'sked__Start__c';
        this.finishFieldApiName = 'sked__Finish__c';
        this.templateEntryApiName = 'sked_Template_Entry__c';
        this.scheduleFieldApiName = 'sked__Recurring_Schedule__c';
        
        this.fieldsToTrackChange = new List<string>();
        this.fieldsToTrackChange.add('sked__Duration__c');
        this.fieldsToTrackChange.add('sked__Job_Status__c');
        this.fieldsToTrackChange.add('sked__Notes_Comments__c');
        this.fieldsToTrackChange.add('sked_Cancellation_Reason__c');
        this.fieldsToTrackChange.add('sked_Cancellation_Reason_Notes__c');
        this.fieldsToTrackChange.add('sked_Is_Care_Team__c');
    }
    
    protected override void doAdditionalMap(sObject sObj, skedModels.event eventModel) {
        sked__Job__c skedJob = (sked__Job__c)sObj;
        skedModels.job job = (skedModels.job)eventModel;

        if (job.duration != null) {
            skedJob.sked__Finish__c = skedDateTimeUtils.addMinutes(skedJob.sked__Start__c, job.duration, job.timezoneSidId);
        }
        else {
            skedJob.sked__Duration__c = skedDateTimeUtils.getDifferenteMinutes(skedJob.sked__Start__c, skedJob.sked__Finish__c);
        }
    }

    protected override skedEventServiceBase.saveResult preSaveRecord(skedModels.event eventModel, List<sObject> allRecords) {
        skedModels.job job = (skedModels.job)eventModel;
        List<sked__Job__c> skedJobs = (List<sked__Job__c>)allRecords;
        populateAppointmentLocation(skedJobs, job);

        skedEventServiceBase.saveResult result = new skedEventServiceBase.saveResult();
        result.success = true;
        return result;
    }

    protected override void postSaveRecord(skedModels.event eventModel, List<sObject> allRecords) {
        skedModels.job job = (skedModels.job)eventModel;
        Set<Id> jobIds = skedUtils.getIdsFromList(allRecords);

        Set<Id> tagIds = new Set<Id>();
        if (job.tagIds != null && !job.tagIds.isEmpty()) {
            tagIds.addAll(job.tagIds);
        }

        Set<Id> excludedTagIds = new Set<Id>();
        if (job.excludedTagIds != null && !job.excludedTagIds.isEmpty()) {
            excludedTagIds.addAll(job.excludedTagIds);
        }

        if (string.isBlank(job.id)) {
            skedJobService.insertJobTags(jobIds, tagIds, false);
            skedJobService.insertJobTags(jobIds, excludedTagIds, true);
        }
        else {
            skedJobService.editJobTags(jobIds, tagIds, false);
            skedJobService.editJobTags(jobIds, excludedTagIds, true);
        }
    }
    /*********************************************************** Private ***********************************************************/
    private static void populateAppointmentLocation(List<sked__Job__c> skedJobs, skedModels.job model) {
        DateTime firstJobStart, lastJobEnd;
        for (sked__Job__c skedJob : skedJobs) {
            if (firstJobStart == null || firstJobStart > skedJob.sked__Start__c) {
                firstJobStart = skedJob.sked__Start__c;
            }
            if (lastJobEnd == null || lastJobEnd < skedJob.sked__Finish__c) {
                lastJobEnd = skedJob.sked__Finish__c;
            }
        }

        List<sked_Client_Availability__c> skedClientAvailabilities = skedClientAvailabilityService.getClientAvailability(model.patientId, firstJobStart, lastJobEnd);
        Map<Id, sked__Location__c> mapServiceLocation 
            = new Map<Id, sked__Location__c>([SELECT Id, sked__Address__c, sked__GeoLocation__Latitude__s,
                                              sked__GeoLocation__Longitude__s
                                              FROM sked__Location__c
                                              WHERE sked__Account__c = :model.patientId]);
        integer availabilityIndex = 0;
        for (sked__Job__c skedJob : skedJobs) {
            for (integer j = availabilityIndex; j < skedClientAvailabilities.size(); j++) {
                sked_Client_Availability__c skedClientAvailability = skedClientAvailabilities.get(j);
                if (skedClientAvailability.sked_Start__c > skedJob.sked__Start__c) {
                    availabilityIndex = j;
                    break;
                }
                if (skedClientAvailability.sked_Finish__c < skedJob.sked__Finish__c) {
                    continue;
                }
                if (mapServiceLocation.containsKey(skedClientAvailability.sked_Service_Location__c)) {
                    sked__Location__c skedLocation = mapServiceLocation.get(skedClientAvailability.sked_Service_Location__c);
                    skedJob.sked__Location__c = skedLocation.Id; 
                    skedJob.sked__Address__c = skedLocation.sked__Address__c;
                    skedJob.sked__GeoLocation__Latitude__s = skedLocation.sked__GeoLocation__Latitude__s;
                    skedJob.sked__GeoLocation__Longitude__s = skedLocation.sked__GeoLocation__Longitude__s;
                }
            }
        }
    }

    /*********************************************************** Public ***********************************************************/
    public static List<sked__Job__c> getJobs(jobQueryModel model) {
        string patientId = model.patientId;
        string caseId = model.caseId;
        DateTime startTime = model.startTime;
        DateTime endTime = model.endTime;
        string jobStatusCancelled = skedConstants.JOB_STATUS_CANCELLED;
        List<string> ignoreJobAllocationStatuses = new List<string>();
        ignoreJobAllocationStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        ignoreJobAllocationStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);

        List<string> fields = new List<string>();
        fields.add('Id');
        fields.add('Name');
        fields.add('sked__Account__c');
        fields.add('sked__Address__c');
        fields.add('sked__Contact__c');
        fields.add('sked__Location__c');
        fields.add('sked__Description__c');
        fields.add('sked__Duration__c');
        fields.add('sked__Finish__c');
        fields.add('sked__GeoLocation__c');
        fields.add('sked__Job_Allocation_Count__c');
        fields.add('sked__Job_Status__c');
        fields.add('sked__Notes_Comments__c');
        fields.add('sked__Quantity__c');
        fields.add('sked__Recurring_Schedule__c');
        fields.add('sked__Region__c');
        fields.add('sked__Start__c');
        fields.add('sked__Timezone__c');
        fields.add('sked__Type__c');
        fields.add('sked_Case__c');
        fields.add('sked_Is_Care_Team__c');
        if (model.addedFields != null && !model.addedFields.isEmpty()) {
            fields.addAll(model.addedFields);
        }
        fields.add('(SELECT sked__Tag__c, sked__Tag__r.Name, sked_Is_Excluded__c FROM sked__JobTags__r)');
        fields.add('(SELECT Id, sked__Job__c, sked_Estimated_Distance__c, sked__Estimated_Travel_Time__c, sked__Resource__c, sked__Resource__r.Name, sked__Resource__r.sked__User__r.SmallPhotoUrl FROM sked__Job_Allocations__r WHERE sked__Status__c NOT IN :ignoreJobAllocationStatuses)');

        List<string> conditions = new List<string>();
        if (model.excludedIds != null && !model.excludedIds.isEmpty()) {
            conditions.add('Id NOT IN :model.excludedIds');
        }
        if (model.jobTypes != null && !model.jobTypes.isEmpty()) {
            conditions.add('sked__Type__c IN :model.jobTypes');
        }
        if (!string.isBlank(patientId)) {
            conditions.add('sked__Account__c = :patientId');
        }
        if (!string.isBlank(caseId)) {
            conditions.add('sked_Case__c = :caseId');
        }
        conditions.add('sked__Start__c < :endTime');
        conditions.add('sked__Finish__c > :startTime');
        conditions.add('sked__Job_Status__c != :jobStatusCancelled');

        string queryStatement = 'SELECT ' + string.join(fields, ', ') + 
                                ' FROM sked__Job__c ' + 
                                ' WHERE ' + string.join(conditions, ' AND ') +
                                ' ORDER BY sked__Start__c ASC';
        system.debug('#job query statement#' + queryStatement);
        return (List<sked__Job__c>)Database.query(queryStatement);
    }

    public static List<skedModels.jobAllocation> editJob(skedModels.job updatedData) {
        editJobModel model = new editJobModel();
        model.updatedData = updatedData;
        model.currentData = [SELECT Id, sked__Start__c, sked__Finish__c, sked__Address__c, sked__Timezone__c,
                             (SELECT Id, sked__Tag__c, sked_Is_Excluded__c
                              FROM sked__JobTags__r),
                             (SELECT Id, sked__Resource__c
                              FROM sked__Job_Allocations__r
                              WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                              AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                             FROM sked__Job__c
                             WHERE Id = :updatedData.Id];
        model.timezoneSidId = model.currentData.sked__Timezone__c;
        
        boolean isImpactedAllocation = checkImpactAllocation(model);

        List<skedModels.jobAllocation> conflictAllocations = new List<skedModels.jobAllocation>();
        if (isImpactedAllocation == true) {
            Set<Id> excludedJobIds = new Set<Id>();
            excludedJobIds.add(updatedData.id);

            List<skedModels.job> inputJobs = new List<skedModels.job>();
            inputJobs.add(updatedData);

            Set<Id> resourceIds = new Set<Id>();
            for (sked__Job_Allocation__c skedAllocation : model.currentData.sked__Job_Allocations__r) {
                resourceIds.add(skedAllocation.sked__Resource__c);
            }

            skedAvailatorParams params = new skedAvailatorParams();
            params.timezoneSidId = model.timezoneSidId;
            params.resourceIds = resourceIds;
            params.inputJobs = inputJobs;
            params.excludedJobIds = excludedJobIds;
            params.enableAccountResourceScore = false;
            params.keepAllAllocations = true;

            skedAvailator availator = new skedAvailator(params);
            List<skedModels.jobAllocation> allAllocations = availator.getAllocations();

            for (skedModels.jobAllocation allocation : allAllocations) {
                if (!allocation.isAvailable) {
                    conflictAllocations.add(allocation);
                }
            }
        }

        return conflictAllocations;
    }

    public static boolean checkImpactAllocation(editJobModel model) {
        skedModels.job updatedData = model.updatedData;
        sked__Job__c currentData = model.currentData;

        boolean isImpacted = false;
        if ((updatedData.address != null && updatedData.address.fullAddress != currentData.sked__Address__c)
            || updatedData.start != currentData.sked__Start__c
            || updatedData.finish != currentData.sked__Finish__c) {
            isImpacted = true;
        }
        if (isImpacted == false && updatedData.tagIds != null && !updatedData.tagIds.isEmpty()) {
            if (currentData.sked__JobTags__r != NULL && !currentData.sked__JobTags__r.isEmpty()) {
                Set<Id> currentTagIds = new Set<Id>();
                for (sked__Job_Tag__c skedJobTag : currentData.sked__JobTags__r) {
                    currentTagIds.add(skedJobTag.sked__Tag__c);
                }
                isImpacted = updatedData.tagIds.size() > currentTagIds.size() || !currentTagIds.containsAll(updatedData.tagIds);
            }
        }
        return isImpacted;
    }

    public static void cancelJob(Id jobId, string cancellationReason) {
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(jobId);
        cancelJobs(jobIds, cancellationReason);
    }

    public static void cancelJobs(Set<Id> jobIds, string cancellationReason) {
        List<sked__Job__c> skedJobs = [SELECT Id,
                                       (SELECT Id
                                        FROM sked__Job_Allocations__r
                                        WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                        AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                                       FROM sked__Job__c
                                       WHERE Id IN :jobIds];
        List<sked__Job_Allocation__c> skedAllocationsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job__c skedJob : skedJobs) {
            skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_CANCELLED;
            if (!string.isBlank(cancellationReason)) {
                skedJob.sked_Cancellation_Reason__c = cancellationReason;
            }

            if (skedJob.sked__Job_Allocations__r != null && !skedJob.sked__Job_Allocations__r.isEmpty()) {
                for (sked__Job_Allocation__c skedAllocation : skedJob.sked__Job_Allocations__r) {
                    skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED;
                    skedAllocationsToUpdate.add(skedAllocation);
                }
            }
        }
        update skedJobs;
        if (!skedAllocationsToUpdate.isEmpty()) {
            update skedAllocationsToUpdate;
        }
    }

    public static void dispatchJob(Id jobId) {
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(jobId);
        dispatchJobs(jobIds);
    }

    public static void dispatchJobs(Set<Id> jobIds) {
        List<sked__Job_Allocation__c> skedAllocations = [SELECT Id
                                                         FROM sked__Job_Allocation__c
                                                         WHERE sked__Job__c IN :jobIds
                                                         AND sked__Status__c = :skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH];
        if (!skedAllocations.isEmpty()) {
            for (sked__Job_Allocation__c skedAlloc : skedAllocations) {
                skedAlloc.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED;
            }
            update skedAllocations;
        }
    }
    
    public static void insertJobTags(Id jobId, Set<Id> tagIds, boolean isExcluded) {
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(jobId);
        insertJobTags(jobIds, tagIds, isExcluded);
    }
    
    public static void insertJobTags(Set<Id> jobIds, Set<Id> tagIds, boolean isExcluded) {
		if (tagIds != NULL && !tagIds.isEmpty()) {
            List<sked__Job_Tag__c> skedJobTags = new  List<sked__Job_Tag__c>();
            for (Id jobId : jobIds) {
                for (string tagId : tagIds) {
                    sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                        sked__Job__c = jobId,
                        sked__Tag__c = tagId,
                        sked_Is_Excluded__c = isExcluded
                    );
                    skedJobTags.add(skedJobTag);
                }
            }
            insert skedJobTags;
        }
	}
	
    public static void editJobTags(Id jobId, Set<Id> tagIds, boolean isExcluded) {
        Set<Id> jobIds = new Set<Id>();
        jobIds.add(jobId);
        editJobTags(jobIds, tagIds, isExcluded);
    }
    
    public static void editJobTags(Set<Id> jobIds, Set<Id> tagIds, boolean isExcluded) {
        List<sked__Job__c> skedJobs = [SELECT Id,
                                       (SELECT Id, sked__Tag__c, sked_Is_Excluded__c
                                        FROM sked__JobTags__r
                                        WHERE sked_Is_Excluded__c = :isExcluded)
                                       FROM sked__Job__c
                                       WHERE Id IN :jobIds];
        List<sked__Job_Tag__c> skedJobTagsToDelete = new List<sked__Job_Tag__c>();
        List<sked__Job_Tag__c> skedJobTagsInsert = new List<sked__Job_Tag__c>();
        for (sked__Job__c skedJob : skedJobs) {
            Set<Id> currentTagIds = new Set<Id>();
            for (sked__Job_Tag__c skedJobTag : skedJob.sked__JobTags__r) {
                currentTagIds.add(skedJobTag.sked__Tag__c);
                if (!tagIds.contains(skedJobTag.sked__Tag__c)) {
                    skedJobTagsToDelete.add(skedJobTag);
                }
            }

            for (string tagId : tagIds) {
                if (!currentTagIds.contains(tagId)) {
                    sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                        sked__Job__c = skedJob.Id,
                        sked__Tag__c = tagId,
                        sked_Is_Excluded__c = isExcluded
                    );
                    skedJobTagsInsert.add(skedJobTag);
                }
            }
        }
        if (!skedJobTagsInsert.isEmpty()) {
            insert skedJobTagsInsert;
        }
        if (!skedJobTagsToDelete.isEmpty()) {
            delete skedJobTagsToDelete;
        }
    }

    public static boolean checkConcurrency(sked__Job__c skedJob, Id resourceId) {
        Set<Id> ecludedJobIds = new Set<Id>();
        ecludedJobIds.add(skedJob.Id);
        return checkConcurrency(skedJob, resourceId, ecludedJobIds);
    }
    
    public static boolean checkConcurrency(sked__Job__c skedJob, Id resourceId, Set<Id> ecludedJobIds) {
        List<sked__Job_Allocation__c> concurrencyAllocations = [SELECT Id
                                                                FROM sked__Job_Allocation__c
                                                                WHERE sked__Resource__c = :resourceId
                                                                AND sked__Job__c NOT IN :ecludedJobIds
                                                                AND sked__Job__r.sked__Start__c < :skedJob.sked__Finish__c
                                                                AND sked__Job__r.sked__Finish__c > :skedJob.sked__Start__c
                                                                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
        return concurrencyAllocations.size() > 0;
    }

    public static void updateJobStatus(Set<Id> jobIds) {
        List<sked__Job__c> skedJobs = [SELECT Id, sked__Job_Allocation_Count__c, sked__Job_Status__c, 
                                       (SELECT Id, sked__Status__c
                                        FROM sked__Job_Allocations__r
                                        WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED) 
                                       FROM sked__Job__c 
                                       WHERE Id IN :jobIds];
        List<sked__Job__c> skedJobsToUpdate = new List<sked__Job__c>();
        for (sked__Job__c skedJob : skedJobs) {
            boolean isAnyPendingDispatch = false;
            for (sked__Job_Allocation__c skedAllocation : skedJob.sked__Job_Allocations__r) {
                if (skedAllocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH) {
                    isAnyPendingDispatch = true;
                }
            }
            if (skedJob.sked__Job_Status__c == skedConstants.JOB_STATUS_PENDING_ALLOCATION || skedJob.sked__Job_Status__c == skedConstants.JOB_STATUS_PENDING_DISPATCH) {
                if (isAnyPendingDispatch == true) {
                    skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_DISPATCH;
                }
                else {
                    skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_DISPATCHED;
                }
                skedJobsToUpdate.add(skedJob);
            }
        }
        if (!skedJobsToUpdate.isEmpty()) {
            update skedJobsToUpdate;
        }
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class editJobModel {
        public string timezoneSidId {get;set;}
        public skedModels.job updatedData {get;set;}
        public sked__Job__c currentData {get;set;}
    }

    public class jobQueryModel {
        public string patientId {get;set;}
        public string caseId {get;set;}
        public DateTime startTime {get;set;}
        public DateTime endTime {get;set;}
        public List<string> jobTypes {get;set;}
        public List<string> addedFields {get;set;}
        public Set<Id> excludedIds {get;set;}
    }

}