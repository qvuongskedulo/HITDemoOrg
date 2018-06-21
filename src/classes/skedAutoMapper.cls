global class skedAutoMapper {
    /************************************************ Singleton stuff ***********************************************/
    private static skedAutoMapper mInstance;
    
    public static skedAutoMapper instance {
        get {
            if (mInstance == null) {
                mInstance = new skedAutoMapper();
            }
            return mInstance;
        }
    }
    
    private skedAutoMapper() { 
    	this.timezoneSidId = UserInfo.getTimeZone().getID();
    }
    /************************************************ Auto Mapper ***********************************************/
    public static final string CUSTOM_FIELDS_EXTENSION = '__c';
	
    protected string timezoneSidId;
    
    public void setTimezoneSidId(string timezoneSidId) {
        this.timezoneSidId = timezoneSidId;
    }

    public Object mapTo(SObject sObj, Type domainType) {
        if (sObj == null) {
            //throw exception
        }
        if (domainType == null) {
            //throw exception
        }
        string sObjectApiName = sObj.getSobjectType().getDescribe().getName();
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectApiName);
        Object domainObject;
        if (config == null) {
            domainObject = doMapping(sObj, domainType);
        }
        else {
            domainObject = doMapping(sObj, domainType, config);
        }
        return domainObject;
    }

    /************************************************ Private methods ***********************************************/
    private Object doMapping(SObject sObj, Type domainType) {
        Object domainObject = null;
        string sObjJsonstring = JSON.serialize(sObj);

        Schema.SObjectType sObjectType = sObj.getSobjectType();
        Schema.DescribeSObjectResult sObejctDescription = sObjectType.getDescribe();
        if (sObejctDescription.isCustom()) {
            Map<string, Object> untypedSObjectMap = (Map<string, Object>) JSON.deserializeUntyped(sObjJsonstring);
            string newKey;
            for (string key : untypedSObjectMap.keySet()) {
                if (key.endsWith(CUSTOM_FIELDS_EXTENSION)) {
                    newKey = key.removeEnd(CUSTOM_FIELDS_EXTENSION);
                    Object value = untypedSObjectMap.remove(key);
                    untypedSObjectMap.put(newKey, value);
                }
            }
            sObjJsonstring = JSON.serialize(untypedSObjectMap);
        }
        domainObject = JSON.deserialize(sObjJsonstring, domainType);
        
        return domainObject;
    } 
    
    private Object doMapping(SObject sObj, Type domainType, skedMappingConfigContainer.mappingConfigModel config) {
        string serializedSObj = JSON.serialize(sObj);

        Map<string, Object> untypedSObjMap = (Map<string, Object>) JSON.deserializeUntyped(serializedSObj);
        Map<string, Object> untypedDomainMap = new Map<string, Object>();
        Map<string, skedModels.address> addressMap = new Map<string, skedModels.address>();
        
        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            List<domainFieldModel> domainFields;
            
            if (fieldConfig.mappingType == 'fullAddress' || fieldConfig.mappingType == 'addressLocation') {
                if (!addressMap.containsKey(fieldConfig.domainFieldName)) {
                    skedModels.address address = new skedModels.address();
                    addressMap.put(fieldConfig.domainFieldName, address);
                }
                skedModels.address address = addressMap.get(fieldConfig.domainFieldName);
                if (fieldConfig.mappingType == 'fullAddress') {
                    List<domainFieldModel> fullAddressDomainFields = mapToDomainField(untypedSObjMap, fieldConfig);
                    if (!fullAddressDomainFields.isEmpty()) {
                        domainFieldModel fullAddressField = fullAddressDomainFields.get(0);
                        address.fullAddress = string.valueOf(fullAddressField.value);
                    }
                }
                else if (fieldConfig.mappingType == 'addressLocation') {
                    List<domainFieldModel> addressLocationDomainFields = mapToDomainField(untypedSObjMap, fieldConfig);
                    if (!addressLocationDomainFields.isEmpty()) {
                        domainFieldModel addressLocationField = addressLocationDomainFields.get(0);
                        Map<string, object> mapGeolocation = (Map<string, object>)addressLocationField.value;
                        if (mapGeolocation != null && !mapGeolocation.isEmpty()) {
                            address.geometry = new skedModels.geometry((decimal)mapGeolocation.get('latitude'), (decimal)mapGeolocation.get('longitude'));
                        }
                    }
                }
            }
            else {
                domainFields = mapToDomainField(untypedSObjMap, fieldConfig);
            }
            if (domainFields != null) {
                for (domainFieldModel domainField : domainFields) {
                    untypedDomainMap.put(domainField.key, domainField.value);
                }
            }
        }
        if (!addressMap.isEmpty()) {
            for (string key : addressMap.keySet()) {
                untypedDomainMap.put(key, addressMap.get(key));
            }
        }
        string serializedDomain = JSON.serialize(untypedDomainMap);
        Object result = JSON.deserialize(serializedDomain, domainType);
        return result;
    }
	
    private List<domainFieldModel> mapToDomainField(Map<string, Object> untypedSObjMap, skedMappingConfigContainer.fieldConfigModel fieldConfig) {
        return mapToDomainField(untypedSObjMap, fieldConfig, 0);
    }    
    
    private List<domainFieldModel> mapToDomainField(Map<string, Object> untypedSObjMap, skedMappingConfigContainer.fieldConfigModel fieldConfig, integer pathIndex) {
        if (pathIndex == fieldConfig.sObjectFieldPaths.size() - 1) {
            List<domainFieldModel> results = new List<domainFieldModel>();
            string sObjectFieldName = fieldConfig.sObjectFieldPaths.get(pathIndex);
            if (untypedSObjMap.containsKey(sObjectFieldName)) {
                Object value = untypedSObjMap.get(sObjectFieldName);

                if (fieldConfig.mappingType == 'datetime' && value != null) {
                    DateTime valueDt = skedDateTimeUtils.getDateTimeFromIsoString(string.valueOf(value));
                    domainFieldModel dateField = new domainFieldModel(fieldConfig.domainFieldName + 'Date', valueDt.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.timezoneSidId));
                    domainFieldModel timeField = new domainFieldModel(fieldConfig.domainFieldName + 'Time', integer.valueOf(valueDt.format('Hmm', this.timezoneSidId)));
                    
                    results.add(dateField);
                    results.add(timeField);
                }
                else {
                    domainFieldModel dataField = new domainFieldModel(fieldConfig.domainFieldName, value);
                    results.add(dataField);
                }
            }
            else {
                if (fieldConfig.mappingType == 'value') {
                    domainFieldModel dataField = new domainFieldModel(fieldConfig.domainFieldName, sObjectFieldName);
                    results.add(dataField);
                }
            }
            return results;
        }
        else {
            if (untypedSObjMap.containsKey(fieldConfig.sObjectFieldPaths.get(pathIndex))) {
                return mapToDomainField((Map<string, Object>)untypedSObjMap.get(fieldConfig.sObjectFieldPaths.get(pathIndex)), fieldConfig, pathIndex + 1);
            }
            return new List<domainFieldModel>();
        }
    }
    
    /************************************************ Nested classes ***********************************************/
    public class domainFieldModel {
        public string key {get;set;}
        public object value {get;set;}
        
        public domainFieldModel(string key, object value) {
            this.key = key;
            this.value = value;
        }
    }
    
}