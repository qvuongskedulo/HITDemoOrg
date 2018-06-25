global class skedNexmoApiData {
    
    public class sendSmsResult extends skedCalloutResultBase {
        public rootObject data {get;set;}
    }
    
    public class rootObject {
        public string message_count { get; set; }
        public List<messageResult> messages { get; set; }
    }
    
    public class messageResult {
        public string to { get; set; }
        public string message_id { get; set; }
        public string status { get; set; }
        public string error_text { get; set; }
        public string network { get; set; }
    }
    
}