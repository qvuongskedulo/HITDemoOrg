public abstract class skedCalloutActionBase {
    
    public skedCalloutResultBase execute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
        beforeExecute();
        skedCalloutResultBase result = doExecute(endPoint, httpMethod, mapHeader, body);
        afterExecute();
        
        return result;
    }
    
    protected virtual void beforeExecute() {
        
    }
    
    protected virtual void afterExecute() {
        
    }
    
    protected virtual skedCalloutResultBase initializeResult() {
        return new skedCalloutResultBase();
    }
    
    protected virtual skedCalloutResultBase doExecute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
        skedCalloutResultBase result = initializeResult();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        if (!string.isBlank(body)) {
            req.setBody(body);
        }
        else {
            req.setHeader('Content-length', '0');
        }
        
        if (httpMethod == 'PATCH') {
            req.setHeader('X-HTTP-Method-Override', 'PATCH');
        }
        for (string headerKey : mapHeader.keySet()) {
            string headerValue = mapHeader.get(headerKey);
            req.setHeader(headerKey, headerValue);
        }
        
        httpMethod = httpMethod == 'PATCH' ? 'POST' : httpMethod;
        req.setMethod(httpMethod);
        req.setTimeout(60000);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        
        string response = res.getBody();
        string status = res.getStatus();
        integer statusCode = res.getStatusCode();

        result.status = status;
        result.statusCode = statusCode;
        
        if (statusCode >= 400) {
            result.success = false;
            throw new skedCalloutException(statusCode, status, response);
        }
        else {
            result = processResponse(response);
            result.success = true;
        }
        
        return result;
    }
    
    protected virtual skedCalloutResultBase processResponse(string response) {
        return null;
    }
    
}