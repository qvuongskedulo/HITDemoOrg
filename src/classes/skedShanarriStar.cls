public with sharing class skedShanarriStar {
    
    public List<Map<Object,Object>> data = new List<Map<Object,Object>>();
    public String acctId {get;set;}
    
    public skedShanarriStar(ApexPages.StandardController controller){
        acctId = controller.getRecord().Id ;
    }
    
    public List<Schema.FieldSetMember> getFields() {
        return SObjectType.sked_Support_Plan__c.FieldSets.ShanarriSet.getFields();
    }
    
    public List<Map<Object,Object>> getData() {
        String query = 'SELECT ';
        List<String> fieldNames = new List<String>();
        
        for(Schema.FieldSetMember f : getFields()){
            query += f.getFieldPath() + ', ';
            fieldNames.add(f.getFieldPath());
        }
        query += 'Id, Name FROM sked_Support_Plan__c where Id=\'' + acctId + '\' LIMIT 1';
        
        SObject myFieldResults = Database.Query(query);
        Schema.DescribeSObjectResult R = myFieldResults.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = R.fields.getmap();
        
        //creates a map of labels and api names
        Map<String,String> labelNameMap = new Map<String,String>();
        for(String key : fieldMap.keySet()){
            labelNameMap.put(fieldMap.get(key).getDescribe().getName(), fieldMap.get(key).getDescribe().getlabel());
        }
        
        //creates a map of labels and values
        for(String f : fieldNames){
            String fieldLabel = labelNameMap.get(f);
            String fieldValue = String.valueOf(myFieldResults.get(f));
            
            Map<Object, Object> m = new Map<Object,Object>();
            m.put('field', fieldLabel);
            m.put('value', fieldValue);
            data.add(m);
        }
        
        return data;
    }
    
}