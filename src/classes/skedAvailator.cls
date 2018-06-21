global class skedAvailator extends skedAvailatorBase {

    public skedAvailator(skedAvailatorParams inputParams) {
        super(inputParams);
    }

    public List<skedModels.jobAllocation> getAllocations() {
        return this.possibleAllocations;
    }

    public Map<Id, skedModels.resource> getMapAvailableResource() {
    	return this.mapAvailableResource;
    }

}