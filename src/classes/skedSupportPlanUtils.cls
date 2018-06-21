public class skedSupportPlanUtils {
    
    //using the old and new maps from the trigger, this way we can check if 'isactive' has changed or not
    public static void setSupportPlanInactive(Map<Id, sked_Support_Plan__c> newMap, Map<Id, sked_Support_Plan__c> oldMap) {
        
        //list to store all contact ids for the given support plans
        List<Id> relatedContacts = new List<Id>();
        
        //list to store the IDS of the active support plans (that we want to keep active)
        List<Id> activePlans = new List<Id>();
        
        //list of support plans we wish to deactivate
        List<sked_Support_Plan__c> plansToDeactivate = new List<sked_Support_Plan__c>();
        
        //loop through the keyset (ids) of the new map        
        for (Id spId :newMap.keySet()) {
            
            //check that it exists in the old map(e.g it is an existing record)
            if (oldMap != null) {
                if (oldMap.get(spId) != null) {
                    //if it does, check that the old value was false and the new value is true
                    if (!oldMap.get(spId).sked_Active__c && newMap.get(spId).sked_Active__c) {
                        //add the contact id to our list for use later
                        relatedContacts.add(newMap.get(spId).sked_Individual__c);
                        // add the support plan id to our list to use later
                        activePlans.add(spId);
                    }
                }
            }
            //if its not in old map, its a new record
            else {
                //check that is is active
                if (newMap.get(spId).sked_Active__c) {
                    
                    //add the contact id to our list for use later
                    relatedContacts.add(newMap.get(spId).sked_Individual__c);
                    
                    // add the support plan id to our list to use later
                    activePlans.add(spId);
                }
            }
        }
        
        //only do this bit if we have some records to work on
        if (relatedContacts.size() > 0) {
            List<sked_Support_Plan__c> relatedPlans = [SELECT ID, sked_Active__c 
                                                       FROM sked_Support_Plan__c 
                                                       WHERE Id NOT IN :activePlans
                                                       AND sked_Individual__c IN :relatedContacts];
            for (sked_Support_Plan__c sp :relatedPlans) {
                
                //if they do not exist in the activePlans list then deactivate them
                if (!activePlans.contains(sp.Id)) {
                    sp.sked_Active__c = false;
                    plansToDeactivate.add(sp);
                }
            }
            SavePoint sp = Database.setSavepoint();
            try {
                update plansToDeactivate;
            }
            catch (exception e) {
                System.debug(e);
                Database.rollback(sp);
                throw e;
            }
        }
    }
}