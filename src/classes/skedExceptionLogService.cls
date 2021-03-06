global class skedExceptionLogService {

	public static List<skedModels.exceptionLog> getPatientExceptionLogs(string patientId) {
		List<skedModels.exceptionLog> excetionLogs = new List<skedModels.exceptionLog>();

		List<sked__Job__c> patientSkedJobs = [SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__Duration__c,
										   	  sked__Type__c, sked__Timezone__c, sked__Job_Allocation_Count__c,
										   	  sked__Address__c, sked__GeoLocation__c, sked__Location__c, sked_Case__c,
										   	  sked_Case__r.CaseNumber, sked__Account__r.Name
										   	  FROM sked__Job__c
										   	  WHERE sked__Account__c = :patientId
										   	  AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
										   	  ORDER BY sked__Start__c];
        if (!patientSkedJobs.isEmpty()) {
	        string timezoneSidId = patientSkedJobs.get(0).sked__Timezone__c;
	        skedAutoMapper.instance.setTimezoneSidId(timezoneSidId);

	        for (integer i = 0; i < patientSkedJobs.size() - 1; i++) {
	        	sked__Job__c currentJob = patientSkedJobs.get(i);
	        	for (integer j = i + 1; j < patientSkedJobs.size(); j++) {
	        		sked__Job__c nextJob = patientSkedJobs.get(j);
	        		if (nextJob.sked__Start__c > currentJob.sked__Finish__c) {
	        			break;
	        		}
	        		if (currentJob.sked__Start__c < nextJob.sked__Finish__c && currentJob.sked__Finish__c > nextJob.sked__Start__c) {
	        			skedModels.exceptionLog exceptionLog = captureExceptionLog(skedConstants.EXCEPTION_CODE_TIME_CONFLICT, currentJob);
	        			excetionLogs.add(exceptionLog);
	        		}
	        	}
	        }

	        for (sked__Job__c skedJob : patientSkedJobs) {
        		if (skedJob.sked__Job_Allocation_Count__c == 0) {
	        		skedModels.exceptionLog exceptionLog = captureExceptionLog(skedConstants.EXCEPTION_CODE_NO_ALLOCATION, skedJob);
	        		excetionLogs.add(exceptionLog);
	        	}
        		if (skedJob.sked__Type__c == skedConstants.JOB_TYPE_TREATMENT) {
	        		if (skedJob.sked__Location__c == null) {
	        			skedModels.exceptionLog exceptionLog = captureExceptionLog(skedConstants.EXCEPTION_CODE_MISSING_LOCATION, skedJob);
	        			excetionLogs.add(exceptionLog);
	        		}
	        	}
	        }
	    }

        List<sked_Exception_Log__c> skedExceptionLogs = [SELECT Id, sked_Exception_Code__c, sked_Job__c, sked_Resource__c
														 FROM sked_Exception_Log__c
														 WHERE sked_Job__r.sked__Account__c = :patientId
														 AND sked_Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
        if (!skedExceptionLogs.isEmpty()) {
	        Set<Id> jobIds = new Set<Id>();
	        Set<Id> resourceIds = new Set<Id>();
	        for (sked_Exception_Log__c skedExceptionLog : skedExceptionLogs) {
	        	jobIds.add(skedExceptionLog.sked_Job__c);
	        	resourceIds.add(skedExceptionLog.sked_Resource__c);
	        }
	        Map<Id, sked__Job__c> mapSkedJob = new Map<Id, sked__Job__c>([SELECT Id, sked__Start__c, sked__Finish__c, 
	        															  sked__Duration__c, sked__Type__c, sked__Timezone__c,
																		  sked__Account__r.Name, sked_Case__r.CaseNumber
																		  FROM sked__Job__c
																		  WHERE Id IN :jobIds]);
            Map<Id, sked__Resource__c> mapSkedResource 
            	= new Map<Id, sked__Resource__c>([SELECT Id, Name, sked__User__r.SmallPhotoUrl, sked__Category__c
            	  								  FROM sked__Resource__c
            	  								  WHERE Id IN :resourceIds]);
            
            string timezoneSidId = mapSkedJob.values().get(0).sked__Timezone__c;
	        skedAutoMapper.instance.setTimezoneSidId(timezoneSidId);

	        for (sked_Exception_Log__c skedExceptionLog : skedExceptionLogs) {
		    	sked__Job__c skedJob = mapSkedJob.get(skedExceptionLog.sked_Job__c);
		    	sked__Resource__c skedResource = mapSkedResource.get(skedExceptionLog.sked_Resource__c);
	        	
	        	skedModels.exceptionLog exceptionLog = captureExceptionLog(skedExceptionLog.sked_Exception_Code__c, skedJob, skedResource);
    			excetionLogs.add(exceptionLog);
	        }
	    }

	    return excetionLogs;
	}

	public static void captureExceptions(List<resourceUnavailabilityModel> unavailabilityList) {
		Set<Id> resourceIds = new Set<Id>();
		Set<Id> availabilityIds = new Set<Id>();
		DateTime minDt, maxDt;
		boolean hasTermination = false;
		for (resourceUnavailabilityModel unavailability : unavailabilityList) {
			resourceIds.add(unavailability.resourceId);
			availabilityIds.add(unavailability.availabilityId);
			if (minDt == NULL || unavailability.startTime < minDt) {
				minDt = unavailability.startTime;
			}
			if (unavailability.endTime != NULL) {
				if (maxDt == NULL || unavailability.endTime > maxDt) {
					maxDt = unavailability.endTime;
				}
			}
			else {
				hasTermination = true;
			}
		}
		if (hasTermination) {
			maxDt = NULL;
		}

		List<sked__Job_Allocation__c> impactedAllocations = getImpactedAllocations(resourceIds, minDt, maxDt);

		List<sked_Exception_Log__c> existingExceptions = [SELECT Id, sked_Job_Allocation__c, sked_Exception_Code__c,
														  sked_Job__r.sked__Start__c, sked_Job__r.sked__Finish__c,
														  sked_Availability__r.sked__Start__c, sked_Availability__r.sked__Finish__c
														  FROM sked_Exception_Log__c
														  WHERE sked_Availability__c IN :availabilityIds
														  AND sked_Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN];
        Map<string, sked_Exception_Log__c> mapExistingException = new Map<string, sked_Exception_Log__c>();
        List<sked_Exception_Log__c> expcetionsToUpdate = new List<sked_Exception_Log__c>();
        for (sked_Exception_Log__c existingException : existingExceptions) {
        	if (existingException.sked_Job__r.sked__Start__c >= existingException.sked_Availability__r.sked__Finish__c
        		|| existingException.sked_Job__r.sked__Finish__c <= existingException.sked_Availability__r.sked__Start__c) {
        		existingException.sked_Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
        		expcetionsToUpdate.add(existingException);
        	}
        	else {
        		string key = existingException.sked_Job_Allocation__c + ':' + existingException.sked_Exception_Code__c;
        		mapExistingException.put(key, existingException);	
        	}
        }
        if (!expcetionsToUpdate.isEmpty()) {
        	update expcetionsToUpdate;
        }

		List<sked_Exception_Log__c> newExceptions = new List<sked_Exception_Log__c>();
		for (resourceUnavailabilityModel unavailability : unavailabilityList) {
			for (sked__Job_Allocation__c impactedAllocation : impactedAllocations) {
				if (impactedAllocation.sked__Resource__c != unavailability.resourceId
					|| impactedAllocation.sked__Job__r.sked__Finish__c < unavailability.startTime) {
					continue;
				}
				if (!string.isBlank(unavailability.accountId) && impactedAllocation.sked__Job__r.sked__Account__c != unavailability.accountId) {
					continue;
				}
				if (unavailability.endTime != NULL && unavailability.endTime <= impactedAllocation.sked__Job__r.sked__Start__c) {
					break;
				}
				string key = impactedAllocation.Id + ':' + unavailability.exceptionCode;
				if (mapExistingException.containsKey(key)) {
					continue;
				}

				sked_Exception_Log__c newException = new sked_Exception_Log__c(
	        		sked_Job__c = impactedAllocation.sked__Job__c,
	        		sked_Job_Allocation__c = impactedAllocation.Id,
	        		sked_Resource__c = impactedAllocation.sked__Resource__c,
	        		sked_Exception_Code__c = unavailability.exceptionCode,
	        		sked_Availability__c = unavailability.availabilityId,
	        		sked_Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
	    		);
	    		newExceptions.add(newException);
			}
		}
        if (!newExceptions.isEmpty()) {
        	insert newExceptions;
        }
	}

    /*********************************************************** Private methods ***********************************************************/
	private static List<sked__Job_Allocation__c> getImpactedAllocations(Set<Id> resourceIds, DateTime startTime, DateTime endTime) {
		List<string> fields = new List<string>();
		fields.add('Id');
		fields.add('sked__Job__c');
		fields.add('sked__Resource__c');
		fields.add('sked__Job__r.sked__Account__c');
		fields.add('sked__Job__r.sked__Start__c');
		fields.add('sked__Job__r.sked__Finish__c');
		fields.add('sked__Job__r.sked__Type__c');
		fields.add('sked__Job__r.sked_Case__c');

		List<string> conditions = new List<string>();
		conditions.add('sked__Resource__c IN :resourceIds');
		if (endTime != NULL) {
			conditions.add('sked__Job__r.sked__Start__c < :endTime');
			conditions.add('sked__Job__r.sked__Finish__c > :startTime');
		}
		else {
			conditions.add('sked__Job__r.sked__Start__c >= :startTime');			
		}
		List<string> jobAllocationDeletedStatuses = new List<string>();
		jobAllocationDeletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
		jobAllocationDeletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);

		conditions.add('sked__Status__c NOT IN :jobAllocationDeletedStatuses');
		conditions.add('sked__Job__r.sked_Case__c != NULL');

		string queryString = 'SELECT ' + string.join(fields, ', ') 
							+ ' FROM sked__Job_Allocation__c'
							+ ' WHERE ' + string.join(conditions, ' AND ')
							+ ' ORDER BY sked__Job__r.sked__Start__c ASC';
 	    return (List<sked__Job_Allocation__c>)Database.query(queryString);
	}

	private static skedModels.exceptionLog captureExceptionLog(string exceptionCode, sked__Job__c skedJob) {
		return captureExceptionLog(exceptionCode, skedJob, null);
	}

	private static skedModels.exceptionLog captureExceptionLog(string exceptionCode, sked__Job__c skedJob, sked__Resource__c skedResource) {
		skedModels.exceptionLog exceptionLog = new skedModels.exceptionLog();
    	exceptionLog.patientName = skedJob.sked__Account__r.Name;
    	exceptionLog.caseNumber = skedJob.sked_Case__r.CaseNumber;
    	exceptionLog.exceptionCode = exceptionCode;

    	skedModels.job job = (skedModels.job)skedAutoMapper.instance.mapTo(skedJob, skedModels.job.class);
    	exceptionLog.job = job;

    	if (skedResource != null) {
    		skedModels.resource resource = (skedModels.resource)skedAutoMapper.instance.mapTo(skedResource, skedModels.resource.class);
        	exceptionLog.resource = resource;
    	}

    	return exceptionLog;
	}

    /*********************************************************** Nested classes ***********************************************************/
	public class resourceUnavailabilityModel {
		public string resourceId {get;set;}
		public string accountId {get;set;}
		public string availabilityId {get;set;}
		public DateTime startTime {get;set;}
		public DateTime endTime {get;set;}
		public string exceptionCode {get;set;}
	}

}