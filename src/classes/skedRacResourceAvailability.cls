global class skedRacResourceAvailability extends skedResourceAvailabilityBase {
    
    public skedRacResourceAvailability(skedAvailatorParams params) {
        super(params);
    }

    protected override void initializeOtherResourceData(Map<Id, skedResourceAvailabilityBase.resourceModel> mapResource) {
    }
	
    protected override void loadResourceEvents(sked__Resource__c skedResource, skedResourceAvailabilityBase.resourceModel resource, string timezoneSidId) {
        for (sked__Availability__c availableBlock : skedResource.sked__Availabilities1__r) {
            if (availableBlock.sked__Is_Available__c == FALSE) {
                continue;
            }
            DateTime availableStart = availableBlock.sked__Start__c;
            DateTime availableEnd = availableBlock.sked__Finish__c;

            for (skedResourceAvailabilityBase.dateslotModel dateslot : resource.mapDateslot.values()) {
                if (dateslot.finish <= availableStart || dateslot.start >= availableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = availableStart < dateslot.start ? dateslot.start : availableStart; 
                    DateTime tempEnd = availableEnd > dateslot.finish ? dateslot.finish : availableEnd;
                    dateslot.addEvent(availableStart, availableEnd, null, true);
                }
            }
        }
        for (sked__Availability__c unavailableBlock : skedResource.sked__Availabilities1__r) {
            if (unavailableBlock.sked__Is_Available__c == TRUE) {
                continue;
            }
            skedModels.availability availability = (skedModels.availability)skedAutoMapper.instance.mapTo(unavailableBlock, skedModels.availability.class);
            resource.events.add(availability);
        }
        
        for (sked__Job_Allocation__c skedAllocation : skedResource.sked__Job_Allocations__r) {
            skedModels.jobAllocation jobAllocation = (skedModels.jobAllocation)skedAutoMapper.instance.mapTo(skedAllocation, skedModels.jobAllocation.class);
            jobAllocation.objectType = 'job';
            resource.events.add(jobAllocation);
        }
        for (sked__Activity__c skedActivity : skedResource.sked__Activities__r) {
            skedModels.activity activity = (skedModels.activity)skedAutoMapper.instance.mapTo(skedActivity, skedModels.activity.class);
            resource.events.add(activity);
        }
        
        for (dateslotModel dateslot : resource.mapDateslot.values()) {
            dateslot.events.sort();
        }
    }
    
}