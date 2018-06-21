global class skedSkeduloApiData {
    
    public static final string LOCATION_HISTORY_EVENT_TYPE_ENROUTE = 'ENROUTE';
    public static final string LOCATION_HISTORY_EVENT_TYPE_CHECKEDIN = 'CHECKEDIN';
    
    global virtual class resultBase extends skedCalloutResultBase {
        
    }
    
    global class locationHistoryResult extends resultBase {
        public List<locationHistoryItem> data {get;set;}
    }
    
    global class locationHistoryItem {
        public string resourceId {get;set;}
        public string eventType {get;set;}
        public string jobId {get;set;}
        public decimal eventTime {get;set;}
        public double locationLat {get;set;}
        public double locationLng {get;set;}
    }
    
    global class dispatchJobResult extends resultBase {
        public Map<string, object> data {get;set;}
    } 
    
    global class dispatchJobData {
        public string jobId {get;set;}
		public string resourceId {get;set;}
		public DateTime dts {get;set;}
		public string protocol {get;set;}
		public boolean success {get;set;}
		public string referenceId {get;set;}
		public string errorMessage {get;set;}
		public string errorCode {get;set;}
    }

}