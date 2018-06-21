global virtual class skedRemoteResultModel {
    public object data {get;set;}
    public boolean success {get;set;}
    public string errorMessage {get;set;}
    public string stackTrace {get;set;}
    public string message {get;set;}
    
    public skedRemoteResultModel() {
        success = true;
        errorMessage = '';
        message = '';
    }
    
    public void getError(Exception ex) {
        this.success = false;
        this.errorMessage = ex.getMessage();
        this.stackTrace = ex.getStackTraceString();
    }
}