public class skedRecurringFactory {
    
    public static sked__Recurring_Schedule__c createSchedule(recurringOption configuration) {
        sked__Recurring_Schedule__c skedSchedule = new sked__Recurring_Schedule__c();
        return skedSchedule;
    }

    public static List<sObject> editRecurring(sObject sourceRecord, recurringOption configuration) {
        List<sObject> recurringRecords = new List<sObject>();
        string sObjectType = sourceRecord.getSObjectType().getDescribe().getName();
        DateTime sourceRecordStart = (DateTime)sourceRecord.get(configuration.startFieldApiName);
        Id sourceRecordId = sourceRecord.Id;

        List<string> fields = new List<string>();
        fields.add(configuration.startFieldApiName);
        fields.add(configuration.finishFieldApiName);
        if (configuration.fieldsToTrackChange != null && !configuration.fieldsToTrackChange.isEmpty()) {
            fields.addAll(configuration.fieldsToTrackChange);
        }

        List<string> conditions = new List<string>();
        string scheduleId = (string)sourceRecord.get(configuration.scheduleFieldApiName);
        conditions.add(configuration.scheduleFieldApiName + ' = :scheduleId');

        if (configuration.editAction == 'all_events') {
            DateTime currentTime = system.now();
            conditions.add(configuration.startFieldApiName + ' > :currentTime');
        }
        else if (configuration.editAction == 'following_events') {
            conditions.add(configuration.startFieldApiName + ' > :sourceRecordStart');
        }

        string queryStatement = 'SELECT ' + string.join(fields, ', ') + 
                                ' FROM ' + sObjectType + ' ' + 
                                ' WHERE Id = :sourceRecordId OR (' + string.join(conditions, ' AND ') + ')' + 
                                ' ORDER BY ' + configuration.startFieldApiName + ' ASC';
        List<sObject> queryResults = Database.query(queryStatement);
        Map<Id, sObject> mapRecord = new Map<Id, sObject>(queryResults);

        sObject originalSourceRecord = mapRecord.get(sourceRecord.Id);
        DateTime sourceStart = (DateTime)originalSourceRecord.get(configuration.startFieldApiName);
        string sourceWeekday = sourceStart.format('EEE', configuration.timezoneSidId);

        DateTime sourceNewStart = (DateTime)sourceRecord.get(configuration.startFieldApiName);
        integer sourceNewStartTime = integer.valueOf(sourceNewStart.format('Hmm', configuration.timezoneSidId));
        integer sourceNewStartTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(sourceNewStartTime);

        DateTime sourceNewEnd = (DateTime)sourceRecord.get(configuration.finishFieldApiName);
        integer sourceNewEndTime = integer.valueOf(sourceNewEnd.format('Hmm', configuration.timezoneSidId));
        integer sourceNewEndTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(sourceNewEndTime);
        
        for (sObject record : queryResults) {
            if (record.Id != sourceRecord.Id) {
                DateTime recordStart = (DateTime)record.get(configuration.startFieldApiName);
                if (configuration.editAction == 'same_weekday') {
                    string recordWeekday = recordStart.format('EEE', configuration.timezoneSidId);
                    if (sourceWeekday != recordWeekday) {
                        continue;
                    }
                }
                if (configuration.isDeleting != true) {
                    DateTime recordFinish = (DateTime)record.get(configuration.finishFieldApiName);

                    DateTime recordStart_dateStart = skedDateTimeUtils.getStartOfDate(recordStart, configuration.timezoneSidId);
                    DateTime recordNewStart = skedDateTimeUtils.addMinutes(recordStart_dateStart, sourceNewStartTimeInMinutes, configuration.timezoneSidId);
                    record.put(configuration.startFieldApiName, recordNewStart);

                    DateTime recordFinish_dateStart = skedDateTimeUtils.getStartOfDate(recordFinish, configuration.timezoneSidId);
                    DateTime recordNewFinish = skedDateTimeUtils.addMinutes(recordFinish_dateStart, sourceNewEndTimeInMinutes, configuration.timezoneSidId);
                    record.put(configuration.finishFieldApiName, recordNewFinish);

                    for (string field : configuration.fieldsToTrackChange) {
                        record.put(field, sourceRecord.get(field));
                    }
                }
                recurringRecords.add(record);
            }
        }

        return recurringRecords;
    }

    public static List<sObject> processRecurring(sObject sourceRecord, recurringOption configuration) {
        List<sObject> recurringRecords = new List<sObject>();
        Map<string, integer> mapWeekdayIndex = getMapWeekdayIndex();
        string timezoneSidId = configuration.timezoneSidId;
        skedModels.template template = configuration.template;

        if (configuration.skipHolidays == true) {
            Set<Date> holidays = getHolidays();
            configuration.skippedDates.addAll(holidays);
        }

        configuration.startDate = skedDateTimeUtils.getDateFromIsoString(template.startDate);
        configuration.endDate = skedDateTimeUtils.getDateFromIsoString(template.endDate);
        integer noOfWeeks = 1;
        for (skedModels.templateEntry entry : template.entries) {        
            noOfWeeks = entry.WeekNo > noOfWeeks ? entry.WeekNo : noOfWeeks;
        }
        
        //rendering template and entries
        populateTemplateId(template, configuration);

        //create recurring schedule
        sked__Recurring_Schedule__c skedSchedule = new sked__Recurring_Schedule__c(
            sked_Template__c = template.id
        );
        insert skedSchedule;
        sourceRecord.put(configuration.scheduleFieldApiName, skedSchedule.Id);

        //rendering recurring records
        DateTime startDateDt = skedDateTimeUtils.getStartOfDate(configuration.startDate, timezoneSidId);
        string startDateWeekday = startDateDt.format('EEE', timezoneSidId).toLowerCase();
        integer startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
        integer startEndDaysDifference = configuration.startDate.daysBetween(configuration.endDate);

        for (skedModels.templateEntry entry : template.entries) {
            integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.startTime);
            integer endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.endTime);
            integer weekdayIndex = mapWeekdayIndex.get(entry.weekday);
            integer daysDifference = weekdayIndex - startDateWeekdayIndex + 7 * (entry.weekNo - 1);

            while (daysDifference <= startEndDaysDifference) {
                Date recurringDate = configuration.startDate.addDays(daysDifference);
                if (!configuration.skippedDates.contains(recurringDate)) {
                    DateTime recurringDateStart = skedDateTimeUtils.addDays(startDateDt, daysDifference, timezoneSidId);
                    DateTime newRecordStart = skedDateTimeUtils.addMinutes(recurringDateStart, startTimeInMinutes, timezoneSidId);
                    DateTime newRecordEnd = skedDateTimeUtils.addMinutes(recurringDateStart, endTimeInMinutes, timezoneSidId);
                    sObject newRecord = sourceRecord.clone();
                    newRecord.put(configuration.templateEntryApiName, entry.id);
                    newRecord.put(configuration.startFieldApiName, newRecordStart);
                    newRecord.put(configuration.finishFieldApiName, newRecordEnd);
                    recurringRecords.add(newRecord);
                }
                daysDifference += 7 * noOfWeeks;
            }
        }

        return recurringRecords;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static Set<Date> getHolidays() {
        Map<string, Set<Date>> mapHolidays = skedUtils.getMapHolidays();
        Set<Date> allHolidays = new Set<Date>();
        if (mapHolidays.containsKey(skedConstants.HOLIDAY_GLOBAL)) {
            Set<Date> globalHolidays = mapHolidays.get(skedConstants.HOLIDAY_GLOBAL);
            allHolidays.addAll(globalHolidays);
        }
        return allHolidays;
    }

    private static void populateTemplateId(skedModels.template template, recurringOption configuration) {
        sked__Availability_Template__c skedTemplate = new sked__Availability_Template__c(
            sked__Start__c = configuration.startDate,
            sked__Finish__c = configuration.endDate
        );
        insert skedTemplate;
        template.id = skedTemplate.Id;

        List<sked__Availability_Template_Entry__c> skedEntries = new List<sked__Availability_Template_Entry__c>();
        Map<string, skedModels.templateEntry> mapEntry = new Map<string, skedModels.templateEntry>();
        for (skedModels.templateEntry entry : template.entries) {
            string key = entry.weekNo + ':' + entry.weekday;
            mapEntry.put(key, entry);

            sked__Availability_Template_Entry__c skedEntry = new sked__Availability_Template_Entry__c(
                sked__Availability_Template__c = skedTemplate.Id,
                sked__Weekday__c = entry.weekday,
                sked__Start_Time__c = entry.startTime,
                sked__Finish_Time__c = entry.endTime,
                sked_Week_No__c = entry.weekNo
            );
            skedEntries.add(skedEntry);
        }
        insert skedEntries;

        for (sked__Availability_Template_Entry__c skedEntry : skedEntries) {
            string key = skedEntry.sked_Week_No__c + ':' + skedEntry.sked__Weekday__c;
            skedModels.templateEntry entry = mapEntry.get(key);
            entry.id = skedEntry.Id;
        }
    }

    private static Map<string, integer> getMapWeekdayIndex() {
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
        public Set<Date> skippedDates {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public boolean skipHolidays {get;set;}
        public skedModels.template template {get;set;}
        
        public string editAction {get;set;} //same_weekday | all_events | following_events
        public boolean isDeleting {get;set;}

        public string startFieldApiName {get;set;}
        public string finishFieldApiName {get;set;}
        public string scheduleFieldApiName {get;set;}
        public string templateEntryApiName {get;set;}
        public List<string> fieldsToTrackChange {get;set;}
        public string timezoneSidId {get;set;}
    }
    
}