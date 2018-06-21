public class skedSyncManager {
    protected skedTriggerContainer.triggerContext triggerContext {get;set;}

    public skedSyncManager(skedTriggerContainer.triggerContext triggerContext) {
        this.triggerContext = triggerContext;
    }
    
    public void execute() {
        if (this.triggerContext.isAfter == true) {
            skedSyncActionBase syncAction;
            if (triggerContext.isInsert == true) {
                syncAction = new skedSyncActions.insertAction(triggerContext);
            }
            else if (triggerContext.isUpdate == true) {
                syncAction = new skedSyncActions.updateAction(triggerContext);
            }
            else if (triggerContext.isDelete == true) {
                syncAction = new skedSyncActions.deleteAction(triggerContext);
            }

            if (syncAction != null) {
                syncAction.execute();
            }
        }
    }
}