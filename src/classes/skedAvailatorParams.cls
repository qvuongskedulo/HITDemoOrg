public class skedAvailatorParams {

    public string timezoneSidId {get;set;}
    public Set<Id> resourceIds {get;set;}
    public Set<Id> excludedJobIds {get;set;}
    public List<skedModels.job> inputJobs {get;set;}

    public string accountId {get;set;}
    public boolean enableAccountResourceScore {get;set;}
    public boolean keepQualifiedAllocations {get;set;}
    public boolean keepAllAllocations {get;set;}
    public boolean isUsingSameTagSet {get;set;}

    public Set<Date> inputDates {get;set;}
    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public DateTime startTime {get;set;}
    public DateTime endTime {get;set;}
    public Set<Id> tagIds {get; set;}
    
    public skedAvailatorParams() {
        this.timezoneSidId = UserInfo.getTimeZone().getID();
        this.resourceIds = new Set<Id>();
        this.excludedJobIds = new Set<Id>();
        this.inputJobs = new List<skedModels.job>();
        this.enableAccountResourceScore = false;
        this.keepQualifiedAllocations = false;
        this.keepAllAllocations = false;
        this.inputDates = new Set<Date>();
        this.tagIds = new Set<Id>();
        this.isUsingSameTagSet = true;
    }
    
}