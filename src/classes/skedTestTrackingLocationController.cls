public class skedTestTrackingLocationController {
    
    public sked__Job_Allocation__c Model {get;set;}
    
    public Date selectedDate {get;set;}
    
    public skedTestTrackingLocationController() {
        this.Model = new sked__Job_Allocation__c();
        this.selectedDate = system.today();
    }
	
    public void Cmd_Execute() {
        if (this.selectedDate == null) {
            this.selectedDate = system.today();
        }
        if (this.Model.sked__Resource__c != NULL) {
            Set<Id> resourceIds = new Set<Id>();
            resourceIds.add(this.Model.sked__Resource__c);
            DateTime startTime = DateTime.newInstance(this.selectedDate, time.newInstance(0, 0, 0, 0));
            DateTime endTime = startTime.addDays(1);
            skedTrackingResourceLocationBatch b = new skedTrackingResourceLocationBatch(resourceIds, startTime, endTime);
            Database.executeBatch(b, 20);
        }
    }
    
}