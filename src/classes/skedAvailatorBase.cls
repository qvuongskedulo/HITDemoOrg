global abstract class skedAvailatorBase {
	
	protected skedAvailatorParams params {get;set;}
    protected integer travelTimeVelocity {get;set;}

    protected DateTime startTime {get;set;}
    protected DateTime endTime {get;set;}
    
    protected skedResourceAvailabilityBase resourceAvailability {get;set;}

    protected List<skedModels.jobAllocation> possibleAllocations {get;set;}
    protected Map<Id, skedModels.resource> mapAvailableResource {get;set;}
    /*********************************************************Constructor***************************************************/
    public skedAvailatorBase(skedAvailatorParams inputParams) {
        this.params = inputParams;
        this.resourceAvailability = new skedResourceAvailability(this.params);
        initialize();
    }

    /*********************************************************Private methods***************************************************/
	private void initialize() {
        this.travelTimeVelocity = skedSetting.instance.Admin.velocity;
        Map<Id, skedResourceAvailabilityBase.resourceModel> mapResource = this.resourceAvailability.initializeResourceList();
        validateResources(mapResource);
    }

    /*********************************************************Validate allocation stuffs***************************************************/
    protected void validateResources(Map<Id, skedResourceAvailabilityBase.resourceModel> mapResource) {
    	this.possibleAllocations = new List<skedModels.jobAllocation>();
    	this.mapAvailableResource = new Map<Id, skedModels.resource>();

    	for (skedModels.job job : this.params.inputJobs) {
    		string jobDateStr = job.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.params.timezoneSidId);
    		skedModels.geometry jobLocation = job.address.geometry;
            if (job.geoLocation == null && job.address != null && job.address.geometry != null) {
                job.geoLocation = Location.newInstance(job.address.geometry.lat, job.address.geometry.lng);
            }

    		for (skedResourceAvailabilityBase.resourceModel resource : mapResource.values()) {
    			if (!resource.mapDateslot.containsKey(jobDateStr)) {
    				continue;
    			}
                
    			boolean isResourceAvailable = true;
                boolean isResourceQualified = true;

    			skedResourceAvailabilityBase.dateslotModel dateslot = resource.mapDateslot.get(jobDateStr);
    			
    			skedModels.event previousEvent, nextEvent;
    			
    			for (integer i = 0; i < dateslot.events.size(); i++) {
                    skedModels.event event = dateslot.events.get(i);
    				if (job.finish < event.start && nextEvent != NULL) {
		                break;
		            }
		            if (event.start < job.finish && event.finish > job.start) {
		            	isResourceAvailable = false;
                        if (event.eventType == 'non-working') {
                            isResourceQualified = false;
                        }
		            	break;
		            }
                    if (event.eventType == 'jobAllocation') {
                        string jobId = ((skedModels.jobAllocation)event).jobId;
                        if (this.params.excludedJobIds.contains(jobId)) {
                            continue;
                        }
                    }
		            if (event.finish <= job.start) {
		                previousEvent = event;
		            }
		            if (event.start >= job.finish) {
		                nextEvent = event;
		            }
    			}
    			integer travelTimeFrom, travelTimeTo;
    			double travelDistanceFrom;
    			skedModels.geometry startFromLocation, goToLocation;
                
                if (isResourceAvailable == true) {
        			if (job.geoLocation != NULL) {
    		            if (previousEvent != NULL && previousEvent.geoLocation != NULL) {
                            travelTimeFrom = getTravelTime(previousEvent.geoLocation, job.geoLocation);
    		                startFromLocation = new skedModels.geometry(previousEvent.geoLocation);
    		                travelDistanceFrom = previousEvent.geoLocation.getDistance(job.geoLocation, 'mi');
    		                if (previousEvent.finish.addMinutes(travelTimeFrom) > job.start) {
    		                    isResourceAvailable = false;
    		                }
    		            } 
    		            else {
    		                if (resource.geoLocation != NULL) {
    		                    startFromLocation = resource.address.geometry;
                                travelTimeFrom = getTravelTime(resource.geoLocation, job.geoLocation);
                                travelDistanceFrom = resource.geoLocation.getDistance(job.geoLocation, 'mi');
    		                }
    		            }
    		            if (nextEvent != NULL && nextEvent.geoLocation != NULL) {
                            goToLocation = new skedModels.geometry(nextEvent.geoLocation);
           	                travelTimeTo = getTravelTime(job.geoLocation, nextEvent.geoLocation);
    		                if (job.finish.addMinutes(travelTimeTo) > nextEvent.start) {
    		                    isResourceAvailable = false;
    		                }
    		            }
    		        }
                }
		        if (this.params.keepAllAllocations == true || isResourceAvailable == true || (this.params.keepQualifiedAllocations == true && isResourceQualified == true)) {
		        	skedModels.jobAllocation possibleAllocation = new skedModels.jobAllocation();
		        	possibleAllocation.resourceId = resource.id;
		        	possibleAllocation.jobId = job.id;
		        	possibleAllocation.startFromLocation = startFromLocation;
                    possibleAllocation.travelTimeFrom = travelTimeFrom;
                    possibleAllocation.travelDistanceFrom = travelDistanceFrom;

		        	possibleAllocation.isAvailable = isResourceAvailable;
		        	possibleAllocation.isQualified = isResourceQualified;
                    possibleAllocation.previousEvent = previousEvent;
                    possibleAllocation.nextEvent = nextEvent;
                    if (possibleAllocation.nextEvent != NULL) {
                        possibleAllocation.travelTimeTo = travelTimeTo;
                        possibleAllocation.goToLocation = goToLocation;
                    }

		        	this.possibleAllocations.add(possibleAllocation);
		        	this.mapAvailableResource.put(resource.id, resource);
		        }
    		}
    	}
    }

    protected integer getTravelTime(Location location1, Location location2) {
        if (travelTimeVelocity <= 0) {
            return 0;
        }
        integer travelTime = -1;
        if (location1 == NULL || location2 == NULL) {
            return travelTime;
        }
        double dist = location1.getDistance(location2, 'km');

        travelTime = ((dist / travelTimeVelocity) * 60).intValue();
        return travelTime;
    }
}