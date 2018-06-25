public class sked_CarePlan_SupportNotesContoller {
	@AuraEnabled
    public static list<sked_Support_Plan_Comment__c> getSupportNotesFromCase(Id caseId) {
        List<sked_Support_Plan__c> supportPlans = [SELECT Id 
                                                   FROM sked_Support_Plan__c 
                                                   WHERE sked_Account__c = :caseId];
        if (supportPlans.isEmpty()) {
            return new list<sked_Support_Plan_Comment__c>();
        }
        list<sked_Support_Plan_Comment__c> supportPlanComments = [SELECT id, sked_Case_Comment__c, sked_Comment__c, sked_Edited_By__c, sked_Public__c, sked_Support_Plan__c, sked_Updated_Date__c
                                                                  FROM sked_Support_Plan_Comment__c 
                                                                  WHERE sked_Support_Plan__c IN :supportPlans
                                                                  ORDER BY sked_Support_Plan__c];
        return supportPlanComments;
    }
}