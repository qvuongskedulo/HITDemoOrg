global class skedClientAvailabilityService extends skedEventServiceBase {

    /*********************************************************** Protected ***********************************************************/
    protected override void initialize() {
        this.sObjectApiName = 'sked_Client_Availability__c';
        this.startFieldApiName = 'sked_Start__c';
        this.finishFieldApiName = 'sked_Finish__c';
        this.templateEntryApiName = 'sked_Template_Entry__c';
        this.scheduleFieldApiName = 'sked_Recurring_Schedule__c';
        
        this.fieldsToTrackChange = new List<string>();
        this.fieldsToTrackChange.add('sked_Notes__c');
        this.fieldsToTrackChange.add('sked_Preferred_Start__c');
        this.fieldsToTrackChange.add('sked_Preferred_Finish__c');
        this.fieldsToTrackChange.add('sked_Service_Location__c');
    }
    
    protected override void doAdditionalMap(sObject sObj, skedModels.event eventModel) {
        skedModels.clientAvailability clientAvailability = (skedModels.clientAvailability)eventModel;
        sked_Client_Availability__c skedClientAvailability = (sked_Client_Availability__c)sObj;

        if (clientAvailability.preferredStartTime != null && clientAvailability.preferredEndTime != null) {
            string timezoneSidId = clientAvailability.timezoneSidId;

            Date startDate = skedDateTimeUtils.getDateFromIsoString(clientAvailability.startDate);
            DateTime startDateDt = skedDateTimeUtils.getStartOfDate(startDate, timezoneSidId);
            integer preferredStartTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(clientAvailability.preferredStartTime);
            skedClientAvailability.sked_Preferred_Start__c = skedDateTimeUtils.addMinutes(startDateDt, preferredStartTimeInMinutes, timezoneSidId);

            Date endDate = skedDateTimeUtils.getDateFromIsoString(clientAvailability.endDate);
            DateTime endDateDt = skedDateTimeUtils.getStartOfDate(endDate, timezoneSidId);
            integer preferredEndTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(clientAvailability.preferredEndTime);
            skedClientAvailability.sked_Preferred_Finish__c = skedDateTimeUtils.addMinutes(endDateDt, preferredEndTimeInMinutes, timezoneSidId);
        }
    }

    protected override skedEventServiceBase.saveResult preSaveRecord(skedModels.event eventModel, List<sObject> allRecords) {
        skedModels.clientAvailability clientAvailability = (skedModels.clientAvailability)eventModel;
        List<sked_Client_Availability__c> skedClientAvailabilities = (List<sked_Client_Availability__c>)allRecords;
        List<conflictModel> conflictResults = skedClientAvailabilityService.validateConflicts(clientAvailability, skedClientAvailabilities);
        boolean isConflictFound = false;
        for (conflictModel conflictResult : conflictResults) {
            if (conflictResult.items != null && !conflictResult.items.isEmpty()) {
                isConflictFound = true;
                break;
            }
        }
        skedEventServiceBase.saveResult result = new skedEventServiceBase.saveResult();
        result.returnedData = conflictResults;
        result.success = isConflictFound == false;
        return result;
    }

    /*********************************************************** Public ***********************************************************/
    public static List<sked_Client_Availability__c> getClientAvailability(string patientId, DateTime startTime, DateTime endTime) {
        return getClientAvailability(patientId, startTime, endTime, null);
    }
    
    public static List<sked_Client_Availability__c> getClientAvailability(string patientId, DateTime startTime, DateTime endTime, Set<Id> excludedIds) {
        List<string> fields = new List<string>();
        fields.add('Id');
        fields.add('sked_Account__c');
        fields.add('sked_Start__c');
        fields.add('sked_Finish__c');
        fields.add('sked_Notes__c');
        fields.add('sked_Preferred_Start__c');
        fields.add('sked_Preferred_Finish__c');
        fields.add('sked_Recurring_Schedule__c');
        fields.add('sked_Service_Location__c');

        List<string> conditions = new List<string>();
        if (excludedIds != null && !excludedIds.isEmpty()) {
            Set<Id> excludedRecordIds = excludedIds;
            conditions.add('Id NOT IN :excludedRecordIds');
        }
        conditions.add('sked_Account__c = :patientId');
        conditions.add('sked_Start__c < :endTime');
        conditions.add('sked_Finish__c > :startTime');

        string queryStatement = 'SELECT ' + string.join(fields, ', ') + 
                                ' FROM sked_Client_Availability__c ' + 
                                ' WHERE ' + string.join(conditions, ' AND ') +
                                ' ORDER BY sked_Start__c ASC';
        return (List<sked_Client_Availability__c>)Database.query(queryStatement);
    }
    
    public static List<conflictModel> validateConflicts(skedModels.clientAvailability eventModel, List<sked_Client_Availability__c> newRecords) {
        skedAutoMapper.instance.setTimezoneSidId(eventModel.timezoneSidId);

        DateTime firstRecordStart, lastRecordEnd;
        List<skedModels.clientAvailability> newModels = new List<skedModels.clientAvailability>();
        List<skedModels.clientAvailability> existingModels = new List<skedModels.clientAvailability>();
        Set<Id> existingRecordIds = new Set<Id>();

        for (sked_Client_Availability__c record : newRecords) {
            if (firstRecordStart == null || firstRecordStart > record.sked_Start__c) {
                firstRecordStart = record.sked_Start__c;
            }
            if (lastRecordEnd == null || lastRecordEnd < record.sked_Finish__c) {
                lastRecordEnd = record.sked_Finish__c;
            }
            skedModels.clientAvailability model = (skedModels.clientAvailability)skedAutoMapper.instance.mapTo(record, skedModels.clientAvailability.class);
            model.start = record.sked_Start__c;
            model.finish = record.sked_Finish__c;
            model.timezoneSidId = eventModel.timezoneSidId;
            newModels.add(model);

            if (!string.isBlank(model.id)) {
                existingRecordIds.add(model.id);
            }
        }
        DateTime firstDateStart = skedDateTimeUtils.getStartOfDate(firstRecordStart, eventModel.timezoneSidId);
        DateTime lastDateEnd = skedDateTimeUtils.getEndOfDate(lastRecordEnd, eventModel.timezoneSidId);

        List<sked_Client_Availability__c> existingRecords = getClientAvailability(eventModel.patientId, firstDateStart, lastDateEnd, existingRecordIds);
        for (sked_Client_Availability__c existingRecord : existingRecords) {
            skedModels.clientAvailability model = (skedModels.clientAvailability)skedAutoMapper.instance.mapTo(existingRecord, skedModels.clientAvailability.class);
            model.start = existingRecord.sked_Start__c;
            model.finish = existingRecord.sked_Finish__c;
            model.timezoneSidId = eventModel.timezoneSidId;
            existingModels.add(model);
        }
        newModels.sort();
        existingModels.sort();
        
        integer existingIndex = 0;
        List<conflictModel> conflicts = new List<conflictModel>();
        for (integer i = 0; i < newModels.size(); i++) {
            skedModels.clientAvailability newModel = newModels.get(i);
            conflictModel conflict = new conflictModel();
            conflict.record = newModel;
            conflict.items = new List<conflictItemModel>();
            
            for (integer j = existingIndex; j < existingModels.size(); j++) {
                skedModels.clientAvailability existingModel = existingModels.get(j);
                if (existingModel.start > newModel.finish) {
                    existingIndex = j;
                    break;
                }
                if (existingModel.finish < newModel.start) {
                    continue;
                }
                conflictItemModel item = new conflictItemModel();
                item.conflictRecord = existingModel;
                item.canMerge = newModel.serviceLocationId == existingModel.serviceLocationId;
                conflict.items.add(item);
            }
            conflict.hasConflict = conflict.items != null && !conflict.items.isEmpty();
            conflicts.add(conflict);
        }
        return conflicts;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class conflictModel {
        public List<conflictItemModel> items {get;set;}
        public skedModels.clientAvailability record {get;set;}
        public boolean hasConflict {get;set;}
    }
    
    public class conflictItemModel {
        public skedModels.clientAvailability conflictRecord {get;set;}
        public boolean canMerge {get;set;}
        public string action {get;set;}
    }
    
}