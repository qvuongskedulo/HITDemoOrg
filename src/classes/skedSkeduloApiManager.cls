global virtual class skedSkeduloApiManager {
    
    public static final string DISPATCH_ENDPOINT = 'https://app.skedulo.com/dispatch';
    public static final string DISTANCE_MATRIX_ENDPOINT = 'callout:Skedulo_API/geoservices/distanceMatrix';
    public static final string LOCATION_HISTORY_ENDPOINT = 'https://app.skedulo.com/location/history';
    
    public static void dispatchJobs(Set<Id> jobIds) {
        List<sked__Job__c> skedJobs = [SELECT Id, Name, sked_API_Error__c, sked_API_Error_Message__c,
                                       (SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c
                                        FROM sked__Job_Allocations__r
                                        WHERE sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED)
                                       FROM sked__Job__c
                                       WHERE Id IN :jobIds];
        List<sked__Job_Allocation__c> skedAllocationsToUpdate = new List<sked__Job_Allocation__c>();
        for (sked__Job__c skedJob : skedJobs) {
            skedSkeduloApiData.dispatchJobResult result = dispatchJob(skedJob.Id);
            if (result.success == false) {
                skedJob.sked_API_Error__c = TRUE;
                skedJob.sked_API_Error_Message__c = 'Error Code: ';
                skedJob.sked_API_Error_Message__c += result.message;
                skedJob.sked_API_Error_Message__c += '\n';
            }
            else {
                skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_DISPATCHED;
                for (sked__Job_Allocation__c skedAllocation : skedJob.sked__Job_Allocations__r) {
                    string resourceResponseString = Json.serialize(result.data.get(skedAllocation.sked__Resource__c));
                    skedSkeduloApiData.dispatchJobData allocResponse = (skedSkeduloApiData.dispatchJobData)Json.deserialize(resourceResponseString, skedSkeduloApiData.dispatchJobData.class);
                    
                    if (allocResponse.success == FALSE) {
                        skedAllocation.sked_API_Error__c = TRUE;
                        skedAllocation.sked_API_Error_Message__c = '';
                        if (!string.isBlank(allocResponse.errorCode)) {
                            skedAllocation.sked_API_Error_Message__c += 'Error Code: ';
                            skedAllocation.sked_API_Error_Message__c += allocResponse.errorCode;
                            skedAllocation.sked_API_Error_Message__c += '\n';
                        }
                        if (!string.isBlank(allocResponse.errorMessage)) {
                            skedAllocation.sked_API_Error_Message__c += 'Error Message: ';
                            skedAllocation.sked_API_Error_Message__c += allocResponse.errorMessage;
                        }
                    }
                    skedAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED;
                    skedAllocationsToUpdate.add(skedAllocation);
                }
            }
        }
        update skedJobs;
        if (!skedAllocationsToUpdate.isEmpty()) {
            update skedAllocationsToUpdate;
        }
    }

    public static void dispatchJobAllocations(Set<Id> jobAllocationIds) {
        List<sked__Job_Allocation__c> skedAllocations = [SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c,
                                                         sked__Job__r.sked__Start__c, sked__Job__r.sked__Recurring_Schedule__c
                                                         FROM sked__Job_Allocation__c
                                                         WHERE Id IN :jobAllocationIds
                                                         ORDER BY sked__Job__r.sked__Start__c];
        Set<Id> jobIdsToUpdateStatus = new Set<Id>();
        Set<string> trackingResourceScheduleList = new Set<string>();
        Map<Id, sked__Job__c> mapErrorJob = new Map<Id, sked__Job__c>();
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            if (skedAllocation.sked__Job__r.sked__Recurring_Schedule__c != NULL) {
                string key = skedAllocation.sked__Resource__c + ':' + skedAllocation.sked__Job__r.sked__Recurring_Schedule__c;
                if (trackingResourceScheduleList.contains(key)) {
                    continue;
                }
                else {
                    trackingResourceScheduleList.add(key);
                }
            }

            skedSkeduloApiData.dispatchJobResult result = dispatchJob(skedAllocation.sked__Job__c, skedAllocation.sked__Resource__c);
            if (result.success == TRUE) {
                string resourceResponseString = Json.serialize(result.data.get(skedAllocation.sked__Resource__c));
                skedSkeduloApiData.dispatchJobData allocResponse = (skedSkeduloApiData.dispatchJobData)Json.deserialize(resourceResponseString, skedSkeduloApiData.dispatchJobData.class);
                if (allocResponse.success == FALSE) {
                    skedAllocation.sked_API_Error__c = TRUE;
                    skedAllocation.sked_API_Error_Message__c = '';
                    if (!string.isBlank(allocResponse.errorCode)) {
                        skedAllocation.sked_API_Error_Message__c += 'Error Code: ';
                        skedAllocation.sked_API_Error_Message__c += allocResponse.errorCode;
                        skedAllocation.sked_API_Error_Message__c += '\n';
                    }
                    if (!string.isBlank(allocResponse.errorMessage)) {
                        skedAllocation.sked_API_Error_Message__c += 'Error Message: ';
                        skedAllocation.sked_API_Error_Message__c += allocResponse.errorMessage;
                    }
                }
                else {
                    jobIdsToUpdateStatus.add(skedAllocation.sked__Job__c);
                }
            }
            else {
                sked__Job__c skedJob = new sked__Job__c(
                    Id = skedAllocation.sked__Job__c,
                    sked_API_Error_Message__c = 'Error Code: ' + result.message
                );
                mapErrorJob.put(skedJob.Id, skedJob);
            }
        }
        update skedAllocations;

        if (!mapErrorJob.isEmpty()) {
            update mapErrorJob.values();
        }
        if (!jobIdsToUpdateStatus.isEmpty()) {
            skedJobService.updateJobStatus(jobIdsToUpdateStatus);
        }
    }
    
    public static skedSkeduloApiData.dispatchJobResult dispatchJob(Id jobId) {
        return dispatchJob(jobId, null);
    }

    public static skedSkeduloApiData.dispatchJobResult dispatchJob(Id jobId, Id resourceId) {
        string endPoint = DISPATCH_ENDPOINT;
        string jobParams = EncodingUtil.urlEncode(jobId, 'UTF-8');
        endPoint = endPoint + '?job=' + jobParams;
        if (!string.isBlank(resourceId)) {
            string resourceParams = EncodingUtil.urlEncode(resourceId, 'UTF-8');
            endPoint = endPoint + '&resource=' + resourceParams;
        }
        string httpMethod = 'POST';
        
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/x-www-form-urlencoded');
        mapHeader.put('apiToken', skedSetting.instance.Admin.skeduloAPIToken);
        
        dispatchJobAction action = new dispatchJobAction();
        skedSkeduloApiData.dispatchJobResult result = (skedSkeduloApiData.dispatchJobResult)action.execute(endPoint, httpMethod, mapHeader, '');
        
        return result;
    }
    
    public static skedSkeduloApiData.locationHistoryResult getLocationHistory(Id resourceId, DateTime startTime, DateTime endTime) {
        string endPoint = LOCATION_HISTORY_ENDPOINT;
        
        string resourceParams = EncodingUtil.urlEncode(resourceId, 'UTF-8');
        endPoint = endPoint + '?resourceId=' + resourceParams;
        string startTimeParams = startTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        endPoint = endPoint + '&from=' + startTimeParams;
        string endTimeParams = endTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        endPoint = endPoint + '&to=' + endTimeParams;
        
        string httpMethod = 'GET';
        
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/x-www-form-urlencoded');
        mapHeader.put('apiToken', skedSetting.instance.Admin.skeduloAPIToken);
        
        locationHistoryAction action = new locationHistoryAction();
        skedSkeduloApiData.locationHistoryResult result = (skedSkeduloApiData.locationHistoryResult)action.execute(endPoint, httpMethod, mapHeader, '');
        return result;
    }

    public static skedSkeduloApiData.distanceMatrixResult calculateDistanceMatrix(List<skedModels.geometry> originList, List<skedModels.geometry> destinationList) {
        string endPoint = DISTANCE_MATRIX_ENDPOINT;
        string httpMethod = 'POST';
        Map<string, string> mapHeader = new Map<string, string>();

        distanceMatrixRequestBody requestBody = new distanceMatrixRequestBody(originList, destinationList);
        string jsonBody = Json.serialize(requestBody);
        
        distanceMatrixAction action = new distanceMatrixAction();
        skedSkeduloApiData.distanceMatrixResult result = (skedSkeduloApiData.distanceMatrixResult)action.execute(endPoint, httpMethod, mapHeader, jsonBody);
        
        return result;
    }
    
    /*************************************************Nested classes*******************************************************/
    global class dispatchJobAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedSkeduloApiData.dispatchJobResult();
        }
        
        protected override skedCalloutResultBase processResponse(string response) {
            skedSkeduloApiData.dispatchJobResult result = new skedSkeduloApiData.dispatchJobResult();
            Map<string, object> deserializedResponse = (Map<string, object>)Json.deserializeUntyped(response);
            result.data = (Map<string, object>)deserializedResponse.get('results');
            return result;
        }
    }
    
    global class locationHistoryAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedSkeduloApiData.locationHistoryResult();
        }
        
        protected override skedCalloutResultBase processResponse(string response) {
            skedSkeduloApiData.locationHistoryResult result = new skedSkeduloApiData.locationHistoryResult();
            result.data = (List<skedSKeduloApiData.locationHistoryItem>)Json.deserialize(response, List<skedSKeduloApiData.locationHistoryItem>.class);
            return result;
        }
    }

    global class distanceMatrixAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedSkeduloApiData.distanceMatrixResult();
        }
        
        protected override skedCalloutResultBase processResponse(string response) {
            system.debug('#response#' + response);
            skedSkeduloApiData.distanceMatrixResult result = new skedSkeduloApiData.distanceMatrixResult();
            Map<string, object> deserializedResponse = (Map<string, object>)Json.deserializeUntyped(response);
            object resultNode = (Map<string, object>)deserializedResponse.get('result');
            string resultNodeJson = Json.serialize(resultNode);
            result.data = (skedSkeduloApiData.Matrix)Json.deserialize(resultNodeJson, skedSkeduloApiData.Matrix.class);
            return result;
        }
    }

    public class distanceMatrixRequestBody {
        public List<skedModels.geometry> origins {get;set;}
        public List<skedModels.geometry> destinations {get;set;}
        
        public distanceMatrixRequestBody(List<skedModels.geometry> originList, List<skedModels.geometry> destinationList) {
            this.origins = originList;
            this.destinations = destinationList;
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

}