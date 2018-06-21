public abstract class skedSyncActionBase {
    /************************************************ Properties member ************************************************/
    protected skedTriggerContainer.triggerContext triggerContext {get;set;}
    protected skedObjectMapper mapper {get;set;}
	
    /************************************************ Public methods **************************************************/
    public void execute() {
        this.mapper = new skedObjectMapper(triggerContext.sObjectName);
        this.doMapping();
    }
    
    /************************************************ Protected methods ***********************************************/
    protected abstract void doMapping();

}