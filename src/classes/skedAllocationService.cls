global class skedAllocationService {

    public scheduleAllocationModel getAllocationData(skedAvailatorParams params) {
        scheduleAllocationModel model = new scheduleAllocationModel();
        model.timezoneSidId = params.timezoneSidId;
        model.jobs = params.inputJobs;

        prepareScheduleAllocationModel(model);
        getAvailableResources(model, params);
        
        return model;
    }
	
    /****************************************************** Private methods ***********************************************************/
    private void prepareScheduleAllocationModel(scheduleAllocationModel model) {
        model.skedJobIds = new Set<Id>();
        model.mapJob = new Map<string, skedModels.job>();
        
        integer jobId = 1;
        for (skedModels.job job : model.jobs) {
            if (!string.isBlank(job.id)) {
                model.skedJobIds.add(job.id);
            }
            else {
                job.id = string.valueOf(jobId);
                jobId++;
            }
            model.mapJob.put(job.id, job);
        }
    }
    
    private void getAvailableResources(scheduleAllocationModel model, skedAvailatorParams params) {
        skedAvailator availator = new skedAvailator(params);
        List<skedModels.jobAllocation> availableAllocations = availator.getAllocations();
        
        Map<Id, skedModels.resource> mapResource = availator.getMapAvailableResource();
        for (skedModels.jobAllocation availableAllocation : availableAllocations) {
            skedModels.job job = model.mapJob.get(availableAllocation.jobId);
            if (job.possibleAllocations == null) {
                job.possibleAllocations = new List<skedModels.jobAllocation>();
            }
            job.possibleAllocations.add(availableAllocation);
            
            skedModels.resource resource = mapResource.get(availableAllocation.resourceId);
            if (resource.noOfAvailableJobs == null) {
                resource.noOfAvailableJobs = 0;
            }
            resource.noOfAvailableJobs++;
        }
        
        //need to include the assigned resources that is no longer available into the allocationData 
        Set<Id> assignedButNotAvailResourceIds = new Set<Id>();
        for (skedModels.job job : model.jobs) {
            if (job.allocations != NULL) {
                for (skedModels.jobAllocation allocation : job.allocations) {
                    if (!mapResource.containsKey(allocation.resourceId)) {
                        assignedButNotAvailResourceIds.add(allocation.resourceId);
                    }
                }
            }
        }
        if (!assignedButNotAvailResourceIds.isEmpty()) {
            List<sked__Resource__c> assignedButNotAvailSkedResources = [SELECT Id, Name, sked__User__r.SmallPhotoUrl
                                                                        FROM sked__Resource__c
                                                                        WHERE Id IN :assignedButNotAvailResourceIds];
            for (sked__Resource__c skedResource : assignedButNotAvailSkedResources) {	
                skedModels.resource resource = new skedModels.resource();
                resource.id = skedResource.Id;
                resource.name = skedResource.Name;
                if (skedResource.sked__User__c != NULL) {
                    resource.photoUrl = skedResource.sked__User__r.SmallPhotoUrl;
                }
                mapResource.put(skedResource.Id, resource);
            }
        }
        model.resources = mapResource.values();
    }
    
    /****************************************************** Nested clases ***********************************************************/
    public class scheduleAllocationModel {
        public string timezoneSidId {get;set;}
        public List<skedModels.job> jobs {get;set;}
        public List<skedModels.resource> resources {get;set;}
        
        public transient Set<Id> skedJobIds {get;set;}
        public transient Set<Id> excludedJobIds {get;set;}
        public transient Set<Id> regionIds {get;set;}
        public transient Set<Id> resourceIds {get;set;}
        public transient Map<string, skedModels.job> mapJob {get;set;}
    }
    
}