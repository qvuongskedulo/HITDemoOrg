public class skedTriggerContainer {

    public skedTriggerContainer() {
        sObjectStack = new List<string>();
    }

    protected List<string> sObjectStack {get;set;}
    
    public void execute(string sObjectName) {
        triggerContext context = getTriggerContext();
        context.sObjectName = sObjectName;
        //tracking sObjectStack
        if (sObjectStack.contains(sObjectName)) {
            return; 
        }
        sObjectStack.add(sObjectName);

        if (skedSetting.Instance.Admin.enableObjectSync == TRUE) {
            skedSyncManager syncManager = new skedSyncManager(context);
            syncManager.execute();
        }
    }
    
    private triggerContext getTriggerContext() {
        triggerContext context = new triggerContext();
        context.isBefore = Trigger.isBefore;
        context.isAfter = Trigger.isAfter;
        context.isInsert = Trigger.isInsert;
        context.isUpdate = Trigger.isUpdate;
        context.isDelete = Trigger.isDelete;
        context.isUndelete = Trigger.isUndelete;
        context.oldRecords = Trigger.old;
        context.newRecords = Trigger.new;
        context.oldMap = Trigger.oldMap;
        
        return context;
    }
    
    /********************************************************* Nested classes ***********************************************************/
    public class triggerContext {
        public boolean isBefore {get;set;}
        public boolean isAfter {get;set;}
        public boolean isInsert {get;set;}
        public boolean isUpdate {get;set;}
        public boolean isDelete {get;set;}
        public boolean isUndelete {get;set;}
        public List<sObject> oldRecords {get;set;}
        public List<sObject> newRecords {get;set;}
        public Map<Id, sObject> oldMap {get;set;}

        public string sObjectName {get;set;}
    }

}