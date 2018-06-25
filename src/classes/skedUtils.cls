public class skedUtils {

    public static Set<Id> getIdsFromList(List<sObject> records) {
        Set<Id> results = new Set<Id>();
        for (sObject record : records) {
            string recordId = string.valueOf(record.get('Id'));
            results.add(recordId);
        }
        return results;
    }

    public static string getRegionTimezoneSidId(Id regionId) {
        sked__Region__c skedRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c WHERE Id = :regionId];
        return skedRegion.sked__Timezone__c;
    }

    public static List<skedModels.selectOption> getPickListOptions(string objectApiName, string fieldApiName) {
        List<string> picklistValues = getPickListValues(objectApiName, fieldApiName);      

        List<skedModels.selectOption> result = new List<skedModels.selectOption>();
        for (string picklistValue : picklistValues) {
            result.add(new skedModels.selectOption(picklistValue, picklistValue));
        }
        return result;
    }

    public static List<string> getPickListValues(string objectApiName, string fieldApiName) {
        List<string> picklistValues = new List<string>();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        DescribeSObjectResult objDescribe = targetType.getDescribe();
        map<String, SObjectField> mapFields = objDescribe.fields.getmap();
        SObjectField fieldType = mapFields.get(fieldApiName);
        DescribeFieldResult fieldResult = fieldType.getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            picklistValues.add(f.getValue());
        }
        return picklistValues;
    }
    
    public static Map<string, Set<Date>> getMapHolidays() {
        Map<string, Set<Date>> mapHolidays = new Map<string, Set<Date>>();
        Date currentDate = system.now().date().addDays(-1);//buffer for different timezone
        
        List<sked__Holiday__c> skedGlobalHolidays = [SELECT Id, sked__Start_Date__c, sked__End_Date__c
                                                     FROM sked__Holiday__c
                                                     WHERE sked__Global__c = TRUE
                                                     AND sked__End_Date__c >= :currentDate];
        List<sked__Holiday_Region__c> skedRegionHolidays = [SELECT Id, sked__Holiday__r.sked__Start_Date__c, sked__Holiday__r.sked__End_Date__c, 
                                                            sked__Region__c, sked__Region__r.Name
                                                            FROM sked__Holiday_Region__c
                                                            WHERE sked__Holiday__r.sked__End_Date__c >= :currentDate];
        
        Set<Date> globalHolidays = new Set<Date>();
        for (sked__Holiday__c globalHoliday : skedGlobalHolidays) {
            Date tempDate = globalHoliday.sked__Start_Date__c;
            while (tempDate <= globalHoliday.sked__End_Date__c) {
                globalHolidays.add(tempDate);
                tempDate = tempDate.addDays(1);
            }
        }
        mapHolidays.put(skedConstants.HOLIDAY_GLOBAL, globalHolidays);
        
        for (sked__Holiday_Region__c regionHoliday : skedRegionHolidays) {
            Set<Date> regionHolidays;
            if (mapHolidays.containsKey(regionHoliday.sked__Region__r.Name)) {
                regionHolidays = mapHolidays.get(regionHoliday.sked__Region__r.Name);
            } else {
                regionHolidays = new Set<Date>();
            }
            
            Date tempDate = regionHoliday.sked__Holiday__r.sked__Start_Date__c;
            while (tempDate <= regionHoliday.sked__Holiday__r.sked__End_Date__c) {
                regionHolidays.add(tempDate);
                tempDate = tempDate.addDays(1);
            }
            
            if (!mapHolidays.containsKey(regionHoliday.sked__Region__r.Name)) {
                mapHolidays.put(regionHoliday.sked__Region__c, regionHolidays);
            }
        }
        return mapHolidays;
    }
    
    public static List<skedModels.selectOption> getTimezones() {
        List<skedModels.selectOption> results = new List<skedModels.selectOption>();
        List<sked__Region__c> itemList = [SELECT Id, sked__Timezone__c FROM sked__Region__c];
        Set<string> allTimezones = new Set<string>();

        string userTimezoneSidId = UserInfo.getTimeZone().getID();
        skedModels.selectOption userTimezoneOption = new skedModels.selectOption(userTimezoneSidId, userTimezoneSidId, true);
        allTimezones.add(userTimezoneSidId);
        results.add(userTimezoneOption);

        for (sked__Region__c item : itemList) {
            if (allTimezones.contains(item.sked__Timezone__c)) {
                continue;
            }
            else {
                allTimezones.add(item.sked__Timezone__c);
            }
            skedModels.selectOption option = new skedModels.selectOption(item.sked__Timezone__c, item.sked__Timezone__c);
            results.add(option);
        }
        return results;
    }

    public static List<skedModels.tag> getTags() {
        List<sked__Tag__c> skedTags = [SELECT Id, Name FROM sked__Tag__c ORDER BY Name];
        List<skedModels.tag> result = new List<skedModels.tag>();
        for (sked__Tag__c skedTag : skedTags) {
            skedModels.tag tag = new skedModels.tag();
            tag.id = skedTag.Id;
            tag.name = skedTag.Name;
            result.add(tag);
        }
        return result;
    }
    
    public static List<skedModels.region> getRegions() {
        return getRegions(null);
    }
    
    public static List<skedModels.region> getRegions(string selectedRegionId) {
        List<sked__Region__c> skedRegions = [SELECT Id, Name, sked__Timezone__c FROM sked__Region__c ORDER BY Name];
        List<skedModels.region> result = new List<skedModels.region>();
        for (sked__Region__c skedRegion : skedRegions) {
            skedModels.region region = new skedModels.region();
            region.id = skedRegion.Id; 
            region.name = skedRegion.Name;
            region.timezoneSidId = skedRegion.sked__Timezone__c;
            result.add(region);
        }
        return result;
    }
    
    public static List<skedModels.serviceLocation> getServiceLocations(string accountId) {
        List<sked__Location__c> skedSeviceLocations = [SELECT Id, Name, sked__Address__c, sked__GeoLocation__c
                                                       FROM sked__Location__c
                                                       WHERE sked__Account__c = :accountId];
        List<skedModels.serviceLocation> results = new List<skedModels.serviceLocation>();
        for (sked__Location__c skedSeviceLocation : skedSeviceLocations) {
            skedModels.serviceLocation serviceLocation = new skedModels.serviceLocation();
            serviceLocation.id = skedSeviceLocation.Id;
            serviceLocation.name = skedSeviceLocation.Name;
            serviceLocation.address = new skedModels.address();
            serviceLocation.address.fullAddress = skedSeviceLocation.sked__Address__c;
            serviceLocation.address.geometry = new skedModels.geometry(skedSeviceLocation.sked__GeoLocation__c);
            results.add(serviceLocation);
        }
        return results;
    }
    
    public static Set<Id> getActiveResourcesByTags(Set<Id> tagIds, Set<Id> regionIds) {
        DateTime currentTime = system.now();
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('(SELECT sked__Tag__c, sked__Resource__c, sked__Expiry_Date__c FROM sked__ResourceTags__r WHERE (sked__Expiry_Date__c = NULL OR sked__Expiry_Date__c >= :currentTime))');

        List<String> conditions = new List<String>();
        conditions.add('sked__Is_Active__c = TRUE');
        if (regionIds != null && !regionIds.isEmpty()) {
            conditions.add('sked__Primary_Region__c IN :regionIds');
        }
        String queryString = 'SELECT ' + String.join(fields, ', ') +
                             ' FROM sked__Resource__c ' +
                             ' WHERE ' + String.join(conditions, ' AND ');
        List<sked__Resource__c> skedResources = (List<sked__Resource__c>)Database.query(queryString);
        List<sked__Resource__c> matchedSkedResources = new List<sked__Resource__c>();
        if (tagIds != NULL && !tagIds.isEmpty()) {
            for (sked__Resource__c skedResource : skedResources) {
                Set<Id> resourceTagIds = new Set<Id>();
                for (sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r) {
                    resourceTagIds.add(resourceTag.sked__Tag__c);
                }
                if (resourceTagIds.containsAll(tagIds)) {
                    matchedSkedResources.add(skedResource);
                }
            }
        }
        else {
            matchedSkedResources = skedResources;
        }
        return new Map<Id, sked__Resource__c>(matchedSkedResources).keySet();
    }

    public static string combineAddress(string street, string city, string state, string postalCode, string country) {
        string address = street;
        if (!string.isBlank(city)) {
            address += ', ' + city;
        }
        if (!string.isBlank(state)) {
            address += ', ' + state;
        }
        if (!string.isBlank(postalCode)) {
            address += ' ' + postalCode;
        }
        if (!string.isBlank(country)) {
            address += ', ' + country;
        }
        return address;
    }

    public static Integer getTravelTime(Location location1, Location location2) {
        if (skedSetting.instance.Admin.velocity <= 0) {
            return 0;
        }
        integer travelTime = -1;
        if (location1 == NULL || location2 == NULL) {
            return travelTime;
        }
        double dist = location1.getDistance(location2, 'mi');

        travelTime = ((dist / skedSetting.instance.Admin.velocity) * 60).intValue();
        return travelTime;
    }

    public static Set<string> getFieldNameFromTemplate(string template) {
        Set<string> filedsWithHierarchy = new Set<string>();
        string extractedFields = extractTemplateToFieldString(template);
        for (string item : extractedFields.split(',')) {
            filedsWithHierarchy.add(item);
        }

        return filedsWithHierarchy;
    }

    public static object getSourceFieldValue(sObject record, string apiFieldName) {
        object outputValue;
        string fullApiFieldNamePath = apiFieldName;
        sObject parentObject = record;
        integer parentIndex = fullApiFieldNamePath.indexOf('.');

        while (parentIndex != -1) {
            if (parentObject == null) {
                return null;
            }
            string parentObjectName = fullApiFieldNamePath.subString(0, fullApiFieldNamePath.indexOf('.'));
            parentObject = parentObject.getSObject(parentObjectName);
            
            fullApiFieldNamePath = fullApiFieldNamePath.subString(fullApiFieldNamePath.indexOf('.') + 1, fullApiFieldNamePath.length());
            parentIndex = fullApiFieldNamePath.indexOf('.');
        }

        outputValue = parentObject.get(fullApiFieldNamePath);
        return outputValue;
    }


    /************************************************ Private methods ***********************************************/
    private static string extractTemplateToFieldString(string template) {
        string field = template.substringBetween('{{','}}');
        if (!String.isBlank(field)) {
            return field + ',' + extractTemplateToFieldString(template.replace('{{' + field + '}}', ''));
        }
        else {
            return '';
        }
    }
    
}