public class skedObjectMapper {
   
    public static final string MAPPING_TYPE_DIRECT = 'Direct';
    public static final string MAPPING_TYPE_COMPOUND = 'Compound';
    public static final string MAPPING_TYPE_MAP = 'Map';
    public static final string MAPPING_TYPE_ADHOC = 'Adhoc';
    public static final string MAPPING_TYPE_DEFAULT = 'Default';
    public static final string MAPPING_TYPE_LOOKUP_TO_LOOKUP = 'Lookup To Lookup';

    protected string sObjectName = '';
    protected List<objectMappingModel> objectMappings {get;set;}

    /************************************************ Public methods ***********************************************/
    public skedObjectMapper(string sObjectName) {
        if (this.objectMappings == null) {
            this.sObjectName = sObjectName;
            initialize(sObjectName);
        }
    }
    
    public map<string, List<sObject>> execute(List<sObject> inputRecords) {
        //system.debug('#####################################################skedObjectMapper########################################################');
        map<string, List<sObject>> map_targetObjectType_outputRecords = new map<string, List<sObject>>();
        
        for (objectMappingModel objectMappingItem : objectMappings) {
            buildsObjectRelation(inputRecords, objectMappingItem);
            //system.debug('######## objectMappingItem: buildsObjectRelation' + objectMappingItem);
            
            buildExistedTargetRecords(objectMappingItem);
            //system.debug('######## objectMappingItem: buildExistedTargetRecords' + objectMappingItem);
            
            buildLookupReferenceRecordMap(objectMappingItem);
            //system.debug('######## objectMappingItem: buildLookupReferenceRecordMap' + objectMappingItem);

            //map based on field mapping configuration
            List<sObject> outputRecords = executeMapping(objectMappingItem);
            //system.debug('######## objectMappingItem: executeMapping outputRecords' + outputRecords);

            //post process: addhoc mapping
            processAdhocMapping(objectMappingItem, outputRecords);
            //system.debug('######## objectMappingItem: processAdhocMapping outputRecords' + outputRecords);

            map_targetObjectType_outputRecords.put(objectMappingItem.targetSObject, outputRecords);
        }

        //system.debug('######## map_targetObjectType_outputRecords ' + map_targetObjectType_outputRecords);
        return map_targetObjectType_outputRecords;
    }

    /************************************************ Public Utility methods ***********************************************/
    public static string extractCompoundField(string compoundField) {
        string field = compoundField.substringBetween('{{','}}');
        if (!String.isBlank(field)) {
            return field + ',' + extractCompoundField(compoundField.replace('{{' + field + '}}', ''));
        }
        else {
            return '';
        }
    }

    public List<objectMappingModel> getObjectMappings() {
        return this.objectMappings;
    }

    /************************************************ Private methods ***********************************************/
	private list<sked_Object_Mapping__c> initialize(string sObjectName) {
        list<sked_Object_Mapping__c> objectsMappingConfig = [SELECT Id, Name, sked_Source_Object__c, sked_Target_Object__c, sked_Custom_Mapper__c, 
                                                             sked_Filter_Condition__c, sked_Target_Identify_Field__c,
                                                             (SELECT Id, sked_Default_Value__c, sked_Is_Active__c, sked_Lookup_Object__c,
                                                              sked_Lookup_Reference_Field__c, sked_Lookup_Target_Field__c, sked_Mapping_Type__c,
                                                              sked_Source_Field__c, sked_Sync_Method__c, sked_Target_Field__c
                                                              FROM sked_Object_Field_Mapping__r
                                                              WHERE sked_Is_Active__c = TRUE),
                                                             (SELECT Id, sked_Key__c, sked_Value__c
                                                              FROM sked_Object_Mapping_Dictionary__r)
                                                             FROM sked_Object_Mapping__c
                                                             WHERE sked_Source_Object__c = :sObjectName
                                                                AND sked_Is_Active__c = TRUE];
        if (!objectsMappingConfig.isEmpty()) {
            this.objectMappings = new List<objectMappingModel>();
            for (sked_Object_Mapping__c objectMappingConfigItem : objectsMappingConfig) {
                objectMappingModel objectMapping = new objectMappingModel(objectMappingConfigItem);
                
                for (sked_Object_Field_Mapping__c fieldMappingConfigItem : objectMappingConfigItem.sked_Object_Field_Mapping__r) {
                    objectFieldMappingModel fieldMapping = new objectFieldMappingModel(fieldMappingConfigItem);
                    objectMapping.fieldsMapping.add(fieldMapping);
                }
                
                for (sked_Object_Mapping_Dictionary__c fieldDictionaryItem : objectMappingConfigItem.sked_Object_Mapping_Dictionary__r) {
                    objectMappingDictionanryModel fieldKeyPairValue = new objectMappingDictionanryModel(fieldDictionaryItem);                    
                    objectMapping.mappingDictionary.add(fieldKeyPairValue);
                }
                
                objectMappings.add(objectMapping);
            }
        }
        
        return objectsMappingConfig;
    }

    private void buildsObjectRelation(List<sObject> inputRecords, skedObjectMapper.objectMappingModel objectMappingItem) {
        set<id> inputRecordIds = new set<id>();
        for (sObject inputRecord : inputRecords) {
            inputRecordIds.add((Id)inputRecord.get('Id'));
        }

        set<string> filedsWithHierarchy = new set<string>();
        for (skedObjectMapper.objectFieldMappingModel fieldMappingItem : objectMappingItem.fieldsMapping) {
            if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_COMPOUND) {
                // remove first 2 characters ', '
                string extractedFields = skedObjectMapper.extractCompoundField(fieldMappingItem.sourceField);
                for (string item : extractedFields.split(',')) {
                    filedsWithHierarchy.add(item.toLowerCase());
                }
            }
            else {
                filedsWithHierarchy.add(fieldMappingItem.sourceField.toLowerCase());
            }
        }
        
        string filedsWithHierarchyBuilder = '';
        for (string item : filedsWithHierarchy) {
            filedsWithHierarchyBuilder += ', ' + item;
            system.debug('############## filedsWithHierarchyBuilder: '+ filedsWithHierarchyBuilder);
        }
        // remove first 2 characters ', '
        filedsWithHierarchyBuilder = filedsWithHierarchyBuilder.substring(2);

        string queryBuilder = '';
        queryBuilder += ' SELECT ' + filedsWithHierarchyBuilder;
        queryBuilder += ' FROM ' + objectMappingItem.sourceSObject;
        queryBuilder += ' WHERE Id IN :inputRecordIds';
        
        if (!string.isBlank(objectMappingItem.filterCondition)) {
            queryBuilder += ' AND ( ' + objectMappingItem.filterCondition + ' ) ';
        }

        objectMappingItem.recordsWithRelationship = Database.query(queryBuilder);
    }

    private void buildExistedTargetRecords(objectMappingModel objectMappingItem) {
        set<Id> inputRecordIds = new set<Id>();
        for (sObject record : objectMappingItem.recordsWithRelationship) {
            inputRecordIds.add((Id) record.get('Id'));
        }

        string queryStatement = 'SELECT Id, ' + objectMappingItem.targetSObjectIdentifyField;
        queryStatement += ' FROM ' + objectMappingItem.targetSObject;
        queryStatement += ' WHERE ' + objectMappingItem.targetSObjectIdentifyField + ' IN :inputRecordIds';

        List<sObject> existedTargetRecords = (List<sObject>)Database.query(queryStatement);

        map<Id, Id> existedTargetRecordsMap = new map<Id, Id>();
        for (sObject record : existedTargetRecords) {
            existedTargetRecordsMap.put((Id)record.get(objectMappingItem.targetSObjectIdentifyField), (Id)record.get('Id'));
        }

        objectMappingItem.existedTargetRecordsMap = existedTargetRecordsMap;
    }

    private void buildLookupReferenceRecordMap(objectMappingModel objectMappingItem) {
        map<string, set<Id>> lookupReferenceIdsMap = new map<string, set<Id>>();
        for (sObject inputRecord : objectMappingItem.recordsWithRelationship) {
            for (objectFieldMappingModel fieldMappingItem : objectMappingItem.fieldsMapping) {
                if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_LOOKUP_TO_LOOKUP) {
                    set<Id> lookupReferenceIds = lookupReferenceIdsMap.get(fieldMappingItem.sourceField);
                    if (lookupReferenceIds == null) {
                        lookupReferenceIds = new set<Id>();
                    }
                    lookupReferenceIds.add((Id)inputRecord.get(fieldMappingItem.sourceField));
                    lookupReferenceIdsMap.put(fieldMappingItem.sourceField, lookupReferenceIds);
                }
            }
        }

        for (objectFieldMappingModel fieldMappingItem : objectMappingItem.fieldsMapping) {
            if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_LOOKUP_TO_LOOKUP) {
                set<id> lookupReferenceIds = lookupReferenceIdsMap.get(fieldMappingItem.sourceField);
                string queryStatement = '';
                queryStatement += ' SELECT ' + fieldMappingItem.lookupReferenceField + ', ' + fieldMappingItem.lookupTargetField;
                queryStatement += ' FROM ' + fieldMappingItem.lookupObject;
                queryStatement += ' WHERE ' + fieldMappingItem.lookupReferenceField + ' IN :lookupReferenceIds';

                List<sObject> lookupResultRecords = Database.query(queryStatement);

                Map<Id, Id> lookupReferenceToTargetMap = new Map<Id, Id>();
                for (sObject lookupResultRecord : lookupResultRecords) {
                    lookupReferenceToTargetMap.put((Id)lookupResultRecord.get(fieldMappingItem.lookupReferenceField), (Id)lookupResultRecord.get(fieldMappingItem.lookupTargetField));
                }

                fieldMappingItem.lookupReferenceRecordMap = lookupReferenceToTargetMap;
            }
        }
    }
    
    private List<sObject> executeMapping(objectMappingModel objectMappingItem) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectMappingItem.targetSObject);
        DescribeSObjectResult objDescribe = targetType.getDescribe();
        map<String, SObjectField> mapFields = objDescribe.fields.getmap();
        
        List<sObject> outputRecords = new List<sObject>();

        for (sObject inputRecord : objectMappingItem.recordsWithRelationship) {
            sObject outputRecord = targetType.newSObject();
            outputRecord.Id = objectMappingItem.existedTargetRecordsMap.get((Id)inputRecord.get('Id'));

            for (objectFieldMappingModel fieldMappingItem : objectMappingItem.fieldsMapping) {
                if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_ADHOC) {
                    continue;
                }

                //system.debug('#################### executeMapping fieldMappingItem.targetField: ' +fieldMappingItem.targetField);
                SObjectField fieldType = mapFields.get(fieldMappingItem.targetField);
                //system.debug('#################### executeMapping fieldType: ' +fieldType);
                Schema.DisplayType outputDataType = fieldType.getDescribe().getType();
                //system.debug('#################### executeMapping outputDataType: ' +outputDataType);

                object outputValue;
                if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_DIRECT) {
                    outputValue = getSourceFieldValue(inputRecord, fieldMappingItem.sourceField);
                } 
                else if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_COMPOUND) {
                    string output = fieldMappingItem.sourceField;
                    for (string field : fieldMappingItem.sourceFields) {
                        system.debug('################################## field: ' + field + ' ###############################');
                        string sourceFieldValue = (string) getSourceFieldValue(inputRecord, field);
                        system.debug('############ sourceFieldValue: ' + sourceFieldValue + ' ###############################');
                        output = output.replace('{{' + field + '}}', sourceFieldValue == null ? '' : sourceFieldValue);
                        system.debug('############ output: ' + output + ' ###############################');
                    }
                    outputValue = output;
                }
                else if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_MAP) {
                    object fieldKey = getSourceFieldValue(inputRecord, fieldMappingItem.sourceField);
                    outputValue = getFieldDictionaryValue(fieldKey, objectMappingItem.mappingDictionary);
                }
                else if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_LOOKUP_TO_LOOKUP) {
                    outputValue = fieldMappingItem.lookupReferenceRecordMap.get((Id)inputRecord.get(fieldMappingItem.sourceField));
                }
                else if (fieldMappingItem.mappingType == skedObjectMapper.MAPPING_TYPE_DEFAULT) {
                    outputValue = fieldMappingItem.defaultValue;
                }

                outputRecord.put(fieldMappingItem.targetField, castValue(outputValue, outputDataType));
            }

            outputRecords.add(outputRecord);
        }

        return outputRecords;
    }

    private void processAdhocMapping(objectMappingModel objectMappingItem, List<sObject> outputRecords) {
        if (string.isBlank(objectMappingItem.customMapper)) {
            return;
        }
        Type customType = Type.forName(objectMappingItem.customMapper);

        skedAdhocMapperBase instance = (skedAdhocMapperBase)customType.newInstance();
        instance.execute(objectMappingItem.recordsWithRelationship, outputRecords);
    }

    private static object getFieldDictionaryValue(object key, list<objectMappingDictionanryModel> fieldValueMapping) {
        for (objectMappingDictionanryModel keyPairValueItem : fieldValueMapping) {
            if (keyPairValueItem.key == key) {
                return keyPairValueItem.value;
            }
        }

        return '';
    }

    /// Get source value include lookup to parent field
    /// Expected format parent__r.parent__r.field__c or parentStandardObject.parentStandardObject.field
    private static object getSourceFieldValue(sObject record, string apiFieldName) {
        object outputValue;
        string fullApiFieldNamePath = apiFieldName;
        sObject parentObject = record;
        integer parentIndex = fullApiFieldNamePath.indexOf('.');

        while (parentIndex != -1) {
            system.debug('########## fullApiFieldNamePath: ' +fullApiFieldNamePath);
            system.debug('########## parentObject: ' +parentObject);
            string parentObjectName = fullApiFieldNamePath.subString(0, fullApiFieldNamePath.indexOf('.'));
            parentObject = parentObject.getSObject(parentObjectName);
            
            fullApiFieldNamePath = fullApiFieldNamePath.subString(fullApiFieldNamePath.indexOf('.') + 1, fullApiFieldNamePath.length());
            parentIndex = fullApiFieldNamePath.indexOf('.');
        }

        system.debug('########## fullApiFieldNamePath: ' +fullApiFieldNamePath);
        system.debug('########## parentObject: ' +parentObject);
        
        outputValue = parentObject.get(fullApiFieldNamePath);
        return outputValue;
    }

    private static object castValue(object inputValue, Schema.DisplayType outputDataType) {
        object outputValue = inputValue;
        if (outputDataType == Schema.DisplayType.Boolean) {
            outputValue = Boolean.valueOf(inputValue);
        }
        else if (outputDataType == Schema.DisplayType.DateTime) {
            outputValue = DateTime.valueOf(inputValue);
        }
        else {
        }

        return outputValue;
    }

    /*********************************************************** Nested classes ***********************************************************/
    public class objectFieldMappingModel {
        public string mappingType {get;set;}
        public List<string> sourceFields {get;set;}
        public string sourceField {get;set;}
        public string targetField {get;set;}
        public string syncMethod {get;set;}

        public string lookupObject {get;set;}
        public string lookupReferenceField {get;set;}
        public string lookupTargetField {get;set;}

        public string defaultValue {get;set;}

        public map<Id, Id> lookupReferenceRecordMap {get;set;}

        public objectFieldMappingModel(sked_Object_Field_Mapping__c fieldMappingConfigItem) {
            if (fieldMappingConfigItem.sked_Mapping_Type__c == skedObjectMapper.MAPPING_TYPE_COMPOUND) {
                string extractedSourceFields = extractCompoundField(fieldMappingConfigItem.sked_Source_Field__c);
                this.sourceFields = extractedSourceFields.split(',');
            }
            
            this.defaultValue = fieldMappingConfigItem.sked_Default_Value__c;

            this.syncMethod = fieldMappingConfigItem.sked_Sync_Method__c;
            this.sourceField = fieldMappingConfigItem.sked_Source_Field__c;
            this.targetField = fieldMappingConfigItem.sked_Target_Field__c;
            this.mappingType = fieldMappingConfigItem.sked_Mapping_Type__c;

            this.lookupObject = fieldMappingConfigItem.sked_Lookup_Object__c;
            this.lookupReferenceField = fieldMappingConfigItem.sked_Lookup_Reference_Field__c;
            this.lookupTargetField = fieldMappingConfigItem.sked_Lookup_Target_Field__c;
        }
    }

    public class objectMappingDictionanryModel {
        public string key {get;set;}
        public string value {get;set;}

        public objectMappingDictionanryModel(sked_Object_Mapping_Dictionary__c fieldDictionaryItem) {
            this.key = fieldDictionaryItem.sked_Key__c;
            this.value = fieldDictionaryItem.sked_Value__c;
        }
    }

    public class objectMappingModel {
        public string sourceSObject {get;set;}
        public string targetSObject {get;set;}
        public string customMapper {get;set;}
        public string filterCondition {get;set;}
        public string targetSObjectIdentifyField {get;set;}

        public list<objectFieldMappingModel> fieldsMapping {get;set;}
        public list<objectMappingDictionanryModel> mappingDictionary {get;set;}

        public list<sObject> recordsWithRelationship {get;set;}
        public map<Id, Id> existedTargetRecordsMap {get;set;}

        public objectMappingModel(sked_Object_Mapping__c objectMappingConfigItem) {
            this.fieldsMapping = new list<objectFieldMappingModel>();
            this.mappingDictionary = new list<objectMappingDictionanryModel>();
            this.recordsWithRelationship = new List<sObject>();
            this.existedTargetRecordsMap = new map<Id,Id>();

            this.sourceSObject = objectMappingConfigItem.sked_Source_Object__c;
            this.targetSObject = objectMappingConfigItem.sked_Target_Object__c;
            this.customMapper = objectMappingConfigItem.sked_Custom_Mapper__c;
            this.filterCondition = objectMappingConfigItem.sked_Filter_Condition__c;
            this.targetSObjectIdentifyField = objectMappingConfigItem.sked_Target_Identify_Field__c;
        }
    }
    
}