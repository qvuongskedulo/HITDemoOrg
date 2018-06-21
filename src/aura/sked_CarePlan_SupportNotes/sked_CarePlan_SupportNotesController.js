({
	initLoadPlanNote : function(component, event, helper) {
		var remoteAction = component.get("c.getSupportNotesFromCase");	
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
    	var caseId;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
    
            if (sParameterName[0] === 'recId') {
                caseId = sParameterName[1];
            }
        }

        remoteAction.setParams({
            "caseId":caseId
        });
        
        remoteAction.setCallback(this,function(res){
            var state = res.getState();
            if(state == "SUCCESS"){
                console.log('res.getReturnValue()',res.getReturnValue());
                component.set("v.planNotes",res.getReturnValue());
            }
        });
        
        $A.enqueueAction(remoteAction);
	}
})