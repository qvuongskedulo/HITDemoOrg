global virtual class skedRecurringService {
	
    public skedRecurringService() {
        
    }
    
    public recurringResult createRecurring(sObject sourceRecord, recurringOption config) {
        recurringResult result = new recurringResult();
        
        preProcessRecurringOption(sourceRecord, config);
        
        createSchedule(result, config);
        
        createRecurringRecords(sourceRecord, result, config, result.skedEntries);
        
        return result;
    }

    public recurringResult updateSchedule(sObject sourceRecord, recurringOption config) {
        recurringResult result = new recurringResult();
        
        preProcessRecurringOption(sourceRecord, config);

        List<sObject> currentRecords = getCurrentRecords(sourceRecord, config);
        system.debug('#currentRecords#' + currentRecords.size());
        Map<Id, List<sObject>> map_entryId_currentRecords = new Map<Id, List<sObject>>();
        for (sObject record : currentRecords) {
            Id entryId = (Id)record.get(config.templateEntryApiName);
            List<sObject> entryRecords;
            if (map_entryId_currentRecords.containsKey(entryId)) {
                entryRecords = map_entryId_currentRecords.get(entryId);
            }
            else {
                entryRecords = new List<sObject>();
                map_entryId_currentRecords.put(entryId, entryRecords);
            }
            entryRecords.add(record);
        }

        sked__Availability_Template__c newSkedTemplate = new sked__Availability_Template__c(
            sked__Start__c = config.startDate,
            sked__Finish__c = config.endDate
        );
        insert newSkedTemplate;

        sked__Recurring_Schedule__c newSkedSchedule = new sked__Recurring_Schedule__c(
            sked_Template__c = newSkedTemplate.Id
        );
        insert newSkedSchedule;

        List<sked__Availability_Template_Entry__c> skedEntriesToCreate = new List<sked__Availability_Template_Entry__c>();
        List<sked__Availability_Template_Entry__c> newSkedEntries = new List<sked__Availability_Template_Entry__c>();
        Map<Id, sked__Availability_Template_Entry__c> map_entryId_newEntry = new Map<Id, sked__Availability_Template_Entry__c>();
        for (skedModels.templateEntry entry : config.schedule.template.entries) {
            sked__Availability_Template_Entry__c skedEntry = new sked__Availability_Template_Entry__c(
                sked__Availability_Template__c = newSkedTemplate.Id,
                sked__Weekday__c = entry.weekday,
                sked__Start_Time__c = entry.startTime,
                sked__Finish_Time__c = entry.endTime,
                sked_Week_No__c = entry.weekNo
            );
            newSkedEntries.add(skedEntry);
            if (entry.action == 'update') {
                map_entryId_newEntry.put(entry.id, skedEntry);
            }
            else if (entry.action == 'create') {
                skedEntriesToCreate.add(skedEntry);
            }
            else if (entry.action == 'delete') {
                List<sObject> entryRecords = map_entryId_currentRecords.get(entry.id);
                system.debug('#entryRecords#' + entryRecords);
                result.recordsToDelete.addAll(entryRecords);
            }
        }
        insert newSkedEntries;

        result.skedSchedule = newSkedSchedule;
        createRecurringRecords(sourceRecord, result, config, skedEntriesToCreate);

        for (Id entryId : map_entryId_newEntry.keySet()) {
            List<sObject> entryRecords = map_entryId_currentRecords.get(entryId);
            sked__Availability_Template_Entry__c newSkedEntry = map_entryId_newEntry.get(entryId);
            for (sObject entryRecord : entryRecords) {
                entryRecord.put(config.templateEntryApiName, newSkedEntry.Id);
            }
        }

        return result;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private void preProcessRecurringOption(sObject sourceRecord, recurringOption config) {
        config.startDate = skedDateTimeUtils.getDateFromIsoString(config.schedule.template.startDate);
        config.endDate = skedDateTimeUtils.getDateFromIsoString(config.schedule.template.endDate);
        config.sObjectType = sourceRecord.getSObjectType().getDescribe().getName();
        config.noOfWeekTemplate = 1;
        for (skedModels.templateEntry entry : config.schedule.template.entries) {        
            config.noOfWeekTemplate = entry.WeekNo > config.noOfWeekTemplate ? entry.WeekNo : config.noOfWeekTemplate;
        }
    }

    private List<sObject> getCurrentRecords(sObject sourceRecord, recurringOption config) {
        string timezoneSidId = config.timezoneSidId;
        DateTime startTime = skedDateTimeUtils.getStartOfDate(config.startDate, timezoneSidId);
        DateTime endTime = skedDateTimeUtils.getEndOfDate(config.endDate, timezoneSidId);

        List<string> fields = new List<string>();
        fields.add(config.templateEntryApiName);
        fields.add(config.startFieldApiName);
        fields.add(config.finishFieldApiName);
        if (config.fieldsToTrackChange != null && !config.fieldsToTrackChange.isEmpty()) {
            fields.addAll(config.fieldsToTrackChange);
        }

        List<string> conditions = new List<string>();
        string scheduleId = (string)sourceRecord.get(config.scheduleFieldApiName);
        Id sourceRecordId = sourceRecord.Id;
        conditions.add(config.scheduleFieldApiName + ' = :scheduleId');
        conditions.add(config.startFieldApiName + ' >= :startTime');
        conditions.add(config.finishFieldApiName + ' <= :endTime');

        string queryStatement = 'SELECT ' + string.join(fields, ', ') + 
                                ' FROM ' + config.sObjectType + ' ' + 
                                ' WHERE Id = :sourceRecordId OR (' + string.join(conditions, ' AND ') + ')' + 
                                ' ORDER BY ' + config.startFieldApiName + ' ASC';
        List<sObject> queryResults = Database.query(queryStatement);
        return queryResults;
    }
    
    private void createSchedule(recurringResult result, recurringOption config) {
        result.skedTemplate = new sked__Availability_Template__c(
            sked__Start__c = config.startDate,
            sked__Finish__c = config.endDate
        );
        insert result.skedTemplate;
        
        result.skedEntries = new List<sked__Availability_Template_Entry__c>();
        for (skedModels.templateEntry entry : config.schedule.template.entries) {
            sked__Availability_Template_Entry__c skedEntry = new sked__Availability_Template_Entry__c(
                sked__Availability_Template__c = result.skedTemplate.Id,
                sked__Weekday__c = entry.weekday,
                sked__Start_Time__c = entry.startTime,
                sked__Finish_Time__c = entry.endTime,
                sked_Week_No__c = entry.weekNo
            );
            result.skedEntries.add(skedEntry);
        }
        insert result.skedEntries;
        
        result.skedSchedule = new sked__Recurring_Schedule__c(
            sked_Template__c = result.skedTemplate.Id
        );
        insert result.skedSchedule;
    }

    private void createRecurringRecords(sObject sourceRecord, recurringResult result, recurringOption config, List<sked__Availability_Template_Entry__c> skedEntries) {
        Map<string, integer> mapWeekdayIndex = getMapWeekdayIndex();
        skedModels.schedule schedule = config.schedule;
        skedModels.template template = schedule.template;
        string timezoneSidId = config.timezoneSidId;

        DateTime startDateDt = skedDateTimeUtils.getStartOfDate(config.startDate, timezoneSidId);
        string startDateWeekday = startDateDt.format('EEE', timezoneSidId).toLowerCase();
        integer startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
        integer startEndDaysDifference = config.startDate.daysBetween(config.endDate);

        for (sked__Availability_Template_Entry__c skedEntry : skedEntries) {
            integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(skedEntry.sked__Start_Time__c);
            integer endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(skedEntry.sked__Finish_Time__c);
            integer weekdayIndex = mapWeekdayIndex.get(skedEntry.sked__Weekday__c);
            integer weekNo = integer.valueOf(skedEntry.sked_Week_No__c);
            integer daysDifference = weekdayIndex - startDateWeekdayIndex + 7 * (weekNo - 1);

            while (daysDifference <= startEndDaysDifference) {
                DateTime recurringDateStart = skedDateTimeUtils.addDays(startDateDt, daysDifference, timezoneSidId);
                DateTime newRecordStart = skedDateTimeUtils.addMinutes(recurringDateStart, startTimeInMinutes, timezoneSidId);
                DateTime newRecordEnd = skedDateTimeUtils.addMinutes(recurringDateStart, endTimeInMinutes, timezoneSidId);
                sObject newRecord = sourceRecord.clone();
                newRecord.put(config.scheduleFieldApiName, result.skedSchedule.Id);
                newRecord.put(config.templateEntryApiName, skedEntry.Id);
                newRecord.put(config.startFieldApiName, newRecordStart);
                newRecord.put(config.finishFieldApiName, newRecordEnd);
                result.recordsToInsert.add(newRecord);

                daysDifference += 7 * config.noOfWeekTemplate;
            }
        }
    }
    
    private Map<string, integer> getMapWeekdayIndex() {
        Map<string, integer> mapWeekdayIndex = new Map<string, integer>();
        mapWeekdayIndex.put('sun', 0);
        mapWeekdayIndex.put('mon', 1);
        mapWeekdayIndex.put('tue', 2);
        mapWeekdayIndex.put('wed', 3);
        mapWeekdayIndex.put('thu', 4);
        mapWeekdayIndex.put('fri', 5);
        mapWeekdayIndex.put('sat', 6);
        return mapWeekdayIndex;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
	public virtual class recurringOption { 
        public skedModels.schedule schedule {get;set;}
        public string timezoneSidId {get;set;}
        public Set<Date> skippedDates {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public integer noOfWeekTemplate {get;set;}
        
        public string sObjectType {get;set;}
    	public string startFieldApiName {get;set;}
        public string finishFieldApiName {get;set;}
        public string scheduleFieldApiName {get;set;}
        public string templateEntryApiName {get;set;}
        public List<string> fieldsToTrackChange {get;set;}
    }
    
    public virtual class recurringResult {
        public sked__Recurring_Schedule__c skedSchedule {get;set;}
        public sked__Availability_Template__c skedTemplate {get;set;}
        public List<sked__Availability_Template_Entry__c> skedEntries {get;set;}
        public List<sObject> recordsToInsert {get;set;}
        public List<sObject> recordsToUpdate {get;set;}
        public List<sObject> recordsToDelete {get;set;}
        
        public recurringResult() {
            this.recordsToInsert = new List<sObject>();
            this.recordsToUpdate = new List<sObject>();
            this.recordsToDelete = new List<sObject>();
        }
    }
    
}