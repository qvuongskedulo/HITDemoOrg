public class skedSupportPlanDeepCloneController {

    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
     // add the instance for the variables being passed by id on the url
    private sked_Support_Plan__c supPlan {get;set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}

    // initialize the controller
    public skedSupportPlanDeepCloneController(ApexPages.StandardController controller) {

        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        supPlan = (sked_Support_Plan__c)controller.getRecord();

    }

    // method called from the VF's action attribute to clone the sp
    public PageReference cloneWithItems() {

         // setup the save point for rollback
         Savepoint sp = Database.setSavepoint();
         sked_Support_Plan__c newSP;

         try {
              //copy the Support Plan - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             supPlan = [SELECT Id, 
                        		Name,
                        		sked_Individual__c,
                        		sked_How_my_support_is_structured__c,
                        		RecordTypeId,
                        		//SHANARRI FIELDS - Child Record Type
                        		sked_Safe_Score__c,
                        		sked_Safe__c,
                        		sked_Healthy_Score__c,
                        		sked_Healthy__c,
                        		sked_Active_Score__c,
                        		sked_Active_SHANARRI__c, 
                        		sked_Nurtured_Score__c,
                        		sked_Nurtured__c,
                        		sked_Achieving_Score__c,
                        		sked_Achieving__c,
                        		sked_Respected_Score__c,
                        		sked_Respected__c,
                        		sked_Responsible_Score__c,
                        		sked_Responsible__c,
                        		sked_Included_Score__c,
                        		sked_Included__c
                        FROM 	sked_Support_Plan__c 
                        WHERE 	Id = :supPlan.id];
             
             newSP = supPlan.clone(false);
             insert newSP;

             // set the id of the new sp created for testing
               newRecordId = newSP.id;

             // copy over the must read information line items
             List<sked_Must_Read_Information__c> mustreadinfo = new List<sked_Must_Read_Information__c>();
             for (sked_Must_Read_Information__c mr : [Select 
                                                 		mri.Id, 
                                                 		mri.Name,
                                                 		mri.sked_Information__c, 
                                                 		mri.sked_Support_Plan__c 
                                                 From 	sked_Must_Read_information__c mri 
                                                 where 	sked_Support_Plan__c = :supPlan.id]) {
                 
                  sked_Must_Read_Information__c newMRI = mr.clone(false);
                  newMRI.sked_Support_Plan__c = newSP.id;
                  mustreadinfo.add(newMRI);
             }
             insert mustreadinfo;
             
             // copy over the support guidance line items
            
             List<sked_Support_Guidance__c> supportguidance = new List<sked_Support_Guidance__c>();
             for (sked_Support_Guidance__c  sg : [Select 
                                                 	sup.Id, 
                                                 	sup.Name,
                                              		sup.sked_Guidance_Information__c,
                                             		sup.sked_Active__c
                                             From 	sked_Support_Guidance__c sup 
                                             where 	sked_Support_Plan__c = :supPlan.id]) {
                 
                  sked_Support_Guidance__c newSG = sg.clone(false);
                  newSG.sked_Support_Plan__c = newSP.id;
                  supportguidance.add(newSG);
             }
             insert supportguidance;
             
             // copy over the Outcome line items
            
             List<sked_Outcome__c> outcomes = new List<sked_Outcome__c>();
             for (sked_Outcome__c  ot : [Select 
                                            out.Id, 
                                            out.Name,
                                    		out.sked_Active__c,
                                    		out.sked_Contact__c,
                                    		out.sked_Description__c,
                                    		out.sked_End_Date__c, 
                                    		out.sked_Progress_Notes__c,
                                    		out.sked_Start_Date__c,
                                    		out.sked_Status__c
                                     From 	sked_Outcome__c out 
                                     where 	sked_Support_Plan__c  = :supPlan.id]) {
                 
                  sked_Outcome__c newOT = ot.clone(false);
                  newOT.sked_Support_Plan__c  = newSP.id;
                  outcomes.add(newOT);
             }
             insert outcomes;
             
            // copy over the Medication line items
            
             List<sked_Medication__c> medication = new List<sked_Medication__c>();
             for (sked_Medication__c  me : [Select 
                                            med.Id, 
                                            med.Name,
                                       		med.sked_Description__c, 
                                       		med.sked_Dosage__c,
                                       		med.sked_End_Date__c,
                                       		med.sked_Frequency__c,
                                       		med.sked_Individual__c,
                                       		med.sked_Start_Date__c
                                     From 	sked_Medication__c med 
                                     where 	sked_Support_Plan__c  = :supPlan.id]) {
                 
                  sked_Medication__c newME = me.clone(false);
                  newME.sked_Support_Plan__c  = newSP.id;
                  medication.add(newME);
             }
             insert medication;
             

         } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
         }

        // Redirect to new record if using salesforce classic 
        // return new PageReference('/'+newSP.id+'/e?retURL=%2F'+newSP.id);
        
        //Redirect to new record if using salesforce Lightning 
		return new PageReference('/one/one.app?#/sObject/'+newSP.id+'/view');
    }
    
}