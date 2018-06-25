global virtual class skedSmsApiManager {
    
    public static final string NEXMO_SMS_ENDPOINT = 'https://rest.nexmo.com/sms/json';
    public static final string SMS_Enroute_Template = 'sked_SMS_Enroute_Template';
    
    public static void sendNexmoEnrouteSms(Set<Id> jobAllocationIds) {
        sked_SMS_Template__mdt skedSmsTemplate = [SELECT sked_Template__c, sked_Phone_Field_API_Name__c
                                                  FROM sked_SMS_Template__mdt
                                                  WHERE DeveloperName = :skedSmsApiManager.SMS_Enroute_Template];
        string smsTemplate = skedSmsTemplate.sked_Template__c;
        string mobilePhoneField = skedSmsTemplate.sked_Phone_Field_API_Name__c;
        Set<string> templateFields = skedUtils.getFieldNameFromTemplate(smsTemplate);
        
        List<string> fields = new List<string>();
        fields.add('Id');
        fields.add(mobilePhoneField);
        fields.addAll(templateFields);
        
        string queryStatement = 'SELECT ' + string.join(fields, ', ') + 
                                ' FROM sked__Job_Allocation__c ' + 
                                ' WHERE Id IN :jobAllocationIds';
        List<sked__Job_Allocation__c> skedAllocations = Database.query(queryStatement);
        List<sked__Job_Allocation__c> skedAllocationsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            Object phoneValue = skedUtils.getSourceFieldValue(skedAllocation, mobilePhoneField);
            if (phoneValue == null) {
                skedAllocation.sked_API_Error__c = true;
                skedAllocation.sked_API_Error_Message__c = 'Nexmo SMS Error Code: NoMobilePhone';
                skedAllocationsToUpdate.add(skedAllocation);
                continue;
            }
            string smsContent = smsTemplate;
            for (string templateField : templateFields) {
                object value = skedUtils.getSourceFieldValue(skedAllocation, templateField);
                string templateFieldValue = value == null ? '' : string.valueOf(value);
                templateField = '{{' + templateField + '}}';
                smsContent = smsContent.replace(templateField, templateFieldValue);
            }
            string phoneNumberStr = string.valueOf(phoneValue);
            phoneNumberStr = phoneNumberStr.replaceAll('[^0-9]+', '');
            nexmoSmsModel model = new nexmoSmsModel();
            model.tfrom = skedSetting.instance.Admin.nexmoFromNumber;
            model.to = phoneNumberStr;
            model.text = smsContent;
            model.api_key = skedSetting.instance.Admin.nexmoApiKey;
            model.api_secret = skedSetting.instance.Admin.nexmoApiSecret;
            string jsonSms = Json.serialize(model);
            jsonSms = jsonSms.replace('tfrom', 'from');
            
            skedNexmoApiData.sendSmsResult result = sendNexmoSms(jsonSms);
            if (result.success == false) {
                skedAllocation.sked_API_Error__c = true;
                skedAllocation.sked_API_Error_Message__c = 'Nexmo SMS Error Code: ';
                skedAllocation.sked_API_Error_Message__c += result.message;
                skedAllocation.sked_API_Error_Message__c += '\n';
                skedAllocationsToUpdate.add(skedAllocation);
            }
            else {
                skedNexmoApiData.messageResult messageResult = result.data.messages.get(0);
                if (!string.isBlank(messageResult.error_text)) {
                    skedAllocation.sked_API_Error__c = true;
                    skedAllocation.sked_API_Error_Message__c = 'Nexmo SMS Error Code: ';
                    skedAllocation.sked_API_Error_Message__c += messageResult.error_text;
                    skedAllocation.sked_API_Error_Message__c += '\n';
                    skedAllocationsToUpdate.add(skedAllocation);
                }
            }
        }
        if (!skedAllocationsToUpdate.isEmpty()) {
            update skedAllocationsToUpdate;
        }
    }
    
    public static skedNexmoApiData.sendSmsResult sendNexmoSms(string jsonBody) {
        string endPoint = NEXMO_SMS_ENDPOINT;
        string httpMethod = 'POST';
        
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/json');
        
        sendNexmoSmsAction action = new sendNexmoSmsAction();
        skedNexmoApiData.sendSmsResult result = (skedNexmoApiData.sendSmsResult)action.execute(endPoint, httpMethod, mapHeader, jsonBody);
        
        return result;
    }
	
    /*************************************************Nested classes*******************************************************/
    global class sendNexmoSmsAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedCalloutResultBase();
        }
        
        protected override skedCalloutResultBase processResponse(string response) {
            skedNexmoApiData.sendSmsResult result = new skedNexmoApiData.sendSmsResult();
            response = response.replace('-', '_');
            result.data = (skedNexmoApiData.rootObject)Json.deserialize(response, skedNexmoApiData.rootObject.class);
            return result;
        }
    }
    
    global virtual class actionBase extends skedCalloutActionBase {
        protected override skedCalloutResultBase doExecute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
            skedCalloutResultBase result;
            try {
                result = super.doExecute(endPoint, httpMethod, mapHeader, body);
            }
            catch (skedCalloutException ex) {
                result = initializeResult();
                result.success = false;
                result.message = ex.response;
            }
            catch (Exception ex) {
                result = initializeResult();
                result.success = false;
                result.message = ex.getMessage() + ' - ' + ex.getStackTraceString();
            }
            return result;
        }
    }
    
    global class nexmoSmsModel {
        public string api_key {get;set;}
        public string api_secret {get;set;}
        public string tfrom {get;set;}
        public string to {get;set;}
        public string text {get;set;}
    }
    
}