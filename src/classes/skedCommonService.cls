global class skedCommonService {

    public static List<skedModels.contact> getAccountContacts(string accountId) {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, Phone, AccountId,
                                  MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                                  FROM Contact
                                  WHERE AccountId = :accountId
                                  ORDER BY Name ASC];
        
        List<skedModels.contact> results = new List<skedModels.contact>();
        for (Contact contact : contacts) {
            skedModels.contact option = (skedModels.contact)skedAutoMapper.instance.mapTo(contact, skedModels.contact.class);
            option.address = new skedModels.address();
            option.address.fullAddress = skedUtils.combineAddress(contact.MailingStreet, contact.MailingCity, contact.MailingState, contact.MailingPostalCode, contact.MailingCountry);
            results.add(option);
        }
        return results;
    }
    
    public static List<skedModels.holiday> getHolidays() {
        List<skedModels.holiday> results = new List<skedModels.holiday>();
        List<sked__Holiday__c> skedGlobalHolidays = [SELECT Id, Name, sked__Start_Date__c, sked__End_Date__c
                                                     FROM sked__Holiday__c
                                                     WHERE sked__Global__c = TRUE];
        for (sked__Holiday__c skedGlobalHoliday : skedGlobalHolidays) {
            skedModels.holiday model = new skedModels.holiday();
            model.id = skedGlobalHoliday.Id;
            model.name = skedGlobalHoliday.Name;
            model.startDate = Json.serialize(skedGlobalHoliday.sked__Start_Date__c).replace('"', '');
            model.endDate = Json.serialize(skedGlobalHoliday.sked__End_Date__c).replace('"', '');
            model.isGlobal = true;
            results.add(model);
        }
        List<sked__Holiday_Region__c> skedRegionHolidays = [SELECT Id, sked__Holiday__c, sked__Holiday__r.Name, sked__Holiday__r.sked__Start_Date__c, sked__Holiday__r.sked__End_Date__c, 
                                                            sked__Region__c, sked__Region__r.Name
                                                            FROM sked__Holiday_Region__c];
        for (sked__Holiday_Region__c skedRegionHoliday : skedRegionHolidays) {
            skedModels.holiday model = new skedModels.holiday();
            model.id = skedRegionHoliday.sked__Holiday__c;
            model.name = skedRegionHoliday.sked__Holiday__r.Name;
            model.startDate = Json.serialize(skedRegionHoliday.sked__Holiday__r.sked__Start_Date__c).replace('"', '');
            model.endDate = Json.serialize(skedRegionHoliday.sked__Holiday__r.sked__End_Date__c).replace('"', '');
            model.isGlobal = false;
            model.regionId = skedRegionHoliday.sked__Region__c;
            results.add(model);
        }
        return results;
    }

    public static List<skedModels.caseModel> getPatientCases(string patientId) {
        List<skedModels.caseModel> results = new List<skedModels.caseModel>();
        List<Case> activeCases = [SELECT Id, CaseNumber, ContactId
                                  FROM Case 
                                  WHERE AccountId = :patientId 
                                  AND Status != :skedConstants.CASE_STATUS_CLOSED];
        for (Case activeCase : activeCases) {
            skedModels.caseModel model = new skedModels.caseModel();
            model.id = activeCase.Id;
            model.name = activeCase.CaseNumber;
            model.contactId = activeCase.ContactId;
            results.add(model);
        }
        return results;
    }

    public static skedModels.schedule getSchedule(string scheduleId) {
        sked__Recurring_Schedule__c skedSchedule = [SELECT Id, sked_Template__c
                                                    FROM sked__Recurring_Schedule__c
                                                    WHERE Id = :scheduleId];
        skedModels.schedule schedule = new skedModels.schedule();
        schedule.id = skedSchedule.Id;
        if (!string.isBlank(skedSchedule.sked_Template__c)) {
            schedule.templateId = skedSchedule.sked_Template__c;
            sked__Availability_Template__c skedTemplate = [SELECT Id, sked__Start__c, sked__Finish__c,
                                                           (SELECT Id, sked__Weekday__c, sked__Start_Time__c, 
                                                            sked__Finish_Time__c, sked_Week_No__c
                                                            FROM sked__Availability_Template_Entries__r)
                                                           FROM sked__Availability_Template__c
                                                           WHERE Id = :skedSchedule.sked_Template__c];
            skedModels.template template = new skedModels.template();
            template.id = skedTemplate.Id;
            template.startDate = Json.serialize(skedTemplate.sked__Start__c).replace('"', '');
            template.endDate = Json.serialize(skedTemplate.sked__Finish__c).replace('"', '');
            template.entries = new List<skedModels.templateEntry>();
            for (sked__Availability_Template_Entry__c skedEntry : skedTemplate.sked__Availability_Template_Entries__r) {
                skedModels.templateEntry entry = new skedModels.templateEntry();
                entry.id = skedEntry.Id;
                entry.startTime = integer.valueOf(skedEntry.sked__Start_Time__c);
                entry.endTime = integer.valueOf(skedEntry.sked__Finish_Time__c);
                entry.weekNo = integer.valueOf(skedEntry.sked_Week_No__c);
                entry.weekday = skedEntry.sked__Weekday__c;
                template.entries.add(entry);
            }

            schedule.template = template;
        }
        return schedule;
    }

}