public class sked_CarePlan_SupportNotesContoller {
	@AuraEnabled
    public static list<sked_Support_Plan_Comment__c> getSupportNotesFromCase(Id caseId) {
        system.debug('################################################# sked_CarePlan_SupportNotesContoller ##########################################');
        system.debug('########## params: caseId = ' + caseId);
        List<sked_Support_Plan__c> supportPlans = [select id from sked_Support_Plan__c where sked_Account__c = :caseId];
        if (supportPlans.isEmpty()) {
            system.debug('########## supportPlans is isEmpty');
            return new list<sked_Support_Plan_Comment__c>();
        }
        system.debug('########## supportPlans:' + supportPlans);

        list<sked_Support_Plan_Comment__c> supportPlanComments = [select id, sked_Case_Comment__c, sked_Comment__c, sked_Edited_By__c, sked_Public__c, sked_Support_Plan__c, sked_Updated_Date__c
                                                            from sked_Support_Plan_Comment__c 
                                                            where sked_Support_Plan__c IN :supportPlans
                                                            order by sked_Support_Plan__c];
        
        system.debug('########## supportPlanComments:' + supportPlanComments);
        
        system.debug('################################################# End sked_CarePlan_SupportNotesContoller #######################################');
        return supportPlanComments;
    }
}