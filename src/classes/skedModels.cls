global class skedModels {

    global virtual class modelBase {
        public string id {get; set;}
        public string name {get; set;}
        public boolean selected {get; set;}
        public string action {get; set;}
    }

    global virtual class event extends modelBase implements Comparable {
        public string objectType {get; set;}
        public string eventType {get; set;}
        public address address {get; set;}
        public string startDate {get; set;}
        public string endDate {get; set;}
        public integer startTime {get; set;}
        public integer endTime {get; set;}
        public integer duration {get; set;}

        public transient string timezoneSidId {get; set;}
        public transient Date eventDate {get; set;}
        public transient DateTime start {get; set;}
        public transient DateTime finish {get; set;}
        public transient Location geoLocation {get; set;}

        public virtual Integer compareTo(Object compareTo) {
            event compareToRecord = (event)compareTo;
            Integer returnValue = 0;

            if (start > compareToRecord.start) {
                returnValue = 1;
            }
            else if (start < compareToRecord.start) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    global virtual class address {
        public string fullAddress {get; set;}
        public geometry geometry {get; set;}
    }

    global virtual class geometry {
        public decimal lat {get; set;}
        public decimal lng {get; set;}

        public geometry(Location geoLocation) {
            if (geoLocation != null) {
                this.lat = geoLocation.getLatitude();
                this.lng = geoLocation.getLongitude();
            }
        }

        public geometry(decimal lat, decimal lng) {
            this.lat = lat;
            this.lng = lng;
        }
    }

    global virtual class journey {
        public geometry origin {get; set;}
        public geometry destination {get; set;}
        public integer travelTime {get; set;}
        public decimal distance {get; set;}
        public string status {get;set;}
    }

    /************************************************ SALESFORCE OBJECT MODELS ************************************************/
    global virtual class caseModel extends modelBase {
        public string contactId {get; set;}
    }

    global virtual class contact extends modelBase {
        public string accountId {get; set;}
        public string firstName {get; set;}
        public string lastName {get; set;}
        public string phone {get; set;}
        public string email {get; set;}
        public string birthdate {get; set;}
        public address address {get; set;}
    }

    /************************************************ SKEDULO MANAGED OBJECT MODELS ************************************************/
    global virtual class accountResourceScore {
        public string accountId {get; set;}
        public string resourceId {get; set;}
        public boolean whitelisted {get; set;}
        public boolean blacklisted {get; set;}
    }

    global virtual class activity extends event {
        public string resourceId {get; set;}
        public string notes {get; set;}
        public string scheduleId {get; set;}
    }

    global virtual class availability extends event {
        public string resourceId {get; set;}
        public string notes {get; set;}
        public boolean isAvailable {get; set;}
        public string status {get; set;}
        public string scheduleId {get; set;}
        public boolean isAllDay {get; set;}
    }

    global virtual class holiday extends modelBase {
        public string startDate {get; set;}
        public string endDate {get; set;}
        public boolean isGlobal {get; set;}
        public string regionId {get; set;}
    }

    global virtual class job extends event {
        public string accountId {get; set;}
        public string cancellationReason {get; set;}
        public string cancellationReasonNotes {get; set;}
        public string caseId {get; set;}
        public string contactId {get; set;}
        public string contactName {get; set;}
        public string description {get; set;}
        public boolean isCareTeam {get; set;}
        public string jobStatus {get; set;}
        public string notes {get; set;}
        public integer quantity {get; set;}
        public string rescheduleJobId {get; set;}
        public string regionId {get; set;}
        public string patientId {get; set;}
        public string scheduleId {get; set;}
        public string serviceLocationId {get; set;}

        public List<job> followups {get; set;}
        public List<jobAllocation> allocations {get; set;}
        public List<jobAllocation> possibleAllocations {get; set;}
        public List<jobOffer> jobOffers {get; set;}

        public List<Id> tagIds {get; set;}
        public List<tag> tags {get; set;}
        public List<Id> excludedTagIds {get; set;}
        public List<tag> excludedTags {get; set;}
        public List<jobAttendee> attendees {get;set;}

        public boolean hasError {get; set;}
        public List<string> errorMessages {get; set;}

        public void loadJobTags(List<sked__Job_Tag__c> jobTags) {
            this.tags = new List<tag>();
            this.tagIds = new List<Id>();

            this.excludedTags = new List<tag>();
            this.excludedTagIds = new List<Id>();

            for (sked__Job_Tag__c jobTag : jobTags) {
                tag tagItem = new tag();
                tagItem.id = jobTag.sked__Tag__c;
                tagItem.name = jobTag.sked__Tag__r.Name;
                if (jobTag.sked_Is_Excluded__c == true) {
                    this.excludedTags.add(tagItem);
                    this.excludedTagIds.add(jobTag.sked__Tag__c);
                }
                else {
                    this.tags.add(tagItem);
                    this.tagIds.add(jobTag.sked__Tag__c);
                }
            }
        }

        public void loadJobAllocations(List<sked__Job_Allocation__c> skedAllocations) {
            this.allocations = new List<jobAllocation>();
            for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
                skedModels.jobAllocation allocation = new skedModels.jobAllocation();
                allocation.id = skedAllocation.Id;
                allocation.jobId = skedAllocation.sked__Job__c;
                allocation.resourceId = skedAllocation.sked__Resource__c;
                if (skedAllocation.sked__Resource__r != null) {
                    skedModels.resource resource = new skedModels.resource();
                    resource.id = skedAllocation.sked__Resource__c;
                    resource.name = skedAllocation.sked__Resource__r.Name;
                    if (skedAllocation.sked__Resource__r.sked__User__r != null) {
                        resource.photoUrl = skedAllocation.sked__Resource__r.sked__User__r.SmallPhotoUrl;
                    }
                    allocation.resource = resource;
                }
                if (skedAllocation.sked__Estimated_Travel_Time__c != NULL) {
                    allocation.travelTimeFrom = integer.valueOf(skedAllocation.sked__Estimated_Travel_Time__c);
                }
                allocation.travelDistanceFrom = skedAllocation.sked_Estimated_Distance__c;
                this.allocations.add(allocation);
            }
        }

        public void loadJobOffers(List<sked_Job_Offer__c> skedJobOffers) {
            this.jobOffers = new List<jobOffer>();
            for (sked_Job_Offer__c skedJobOffer : skedJobOffers) {
                skedModels.jobOffer jobOffer = new skedModels.jobOffer();
                jobOffer.id = skedJobOffer.Id;
                jobOffer.jobId = skedJobOffer.sked_Job__c;
                jobOffer.resourceId = skedJobOffer.sked_Resource__c;
                if (skedJobOffer.sked_Resource__r != null) {
                    skedModels.resource resource = new skedModels.resource();
                    resource.id = skedJobOffer.sked_Resource__c;
                    resource.name = skedJobOffer.sked_Resource__r.Name;
                    if (skedJobOffer.sked_Resource__r.sked__User__r != null) {
                        resource.photoUrl = skedJobOffer.sked_Resource__r.sked__User__r.SmallPhotoUrl;
                    }
                    jobOffer.resource = resource;
                }
                if (skedJobOffer.sked_Estimated_Travel_Time__c != NULL) {
                    jobOffer.travelTimeFrom = integer.valueOf(skedJobOffer.sked_Estimated_Travel_Time__c);
                }
                jobOffer.travelDistanceFrom = skedJobOffer.sked_Estimated_Distance__c;
                this.jobOffers.add(jobOffer);
            }
        }
    }

    global virtual class jobAllocation extends event {
        public string jobId {get; set;}
        public string resourceId {get; set;}
        public string resourceName {get; set;}

        public job job {get; set;}
        public resource resource {get; set;}

        public geometry startFromLocation {get; set;}
        public integer travelTimeFrom {get; set;}
        public decimal travelDistanceFrom {get; set;}
        public geometry goToLocation {get; set;}
        public integer travelTimeTo {get; set;}
        public decimal travelDistanceTo {get; set;}
        public boolean isQualified {get; set;}
        public boolean isAvailable {get; set;}

        public transient event previousEvent {get; set;}
        public transient event nextEvent {get; set;}
    }

    global virtual class resource extends modelBase {
        public string category {get; set;}
        public string photoUrl {get; set;}
        public string regionId {get; set;}
        public string userId {get; set;}
        public string timezoneSidId {get; set;}
        public integer rating {get; set;}
        public address address {get; set;}
        public List<tag> tags {get; set;}

        public string regionName {get; set;}
        public integer noOfAvailableJobs {get; set;}
        public accountResourceScore accountResourceScore {get; set;}

        public transient DateTime firstTagExpiry {get; set;}
        public transient Set<Id> tagIds {get; set;}
        public transient Location geoLocation {get; set;}

        public void loadResourceTags(List<sked__Resource_Tag__c> resourceTags) {
            loadResourceTags(resourceTags, NULL);
        }

        public void loadResourceTags(List<sked__Resource_Tag__c> resourceTags, Set<Id> requiredTagIds) {
            this.tags = new List<tag>();
            this.tagIds = new Set<Id>();
            for (sked__Resource_Tag__c resourceTag : resourceTags) {
                if (requiredTagIds == NULL || requiredTagIds.contains(resourceTag.sked__Tag__c)) {
                    this.tagIds.add(resourceTag.sked__Tag__c);

                    tag tagItem = new tag();
                    tagItem.id = resourceTag.sked__Tag__c;
                    tagItem.expiryTime = resourceTag.sked__Expiry_Date__c;
                    this.tags.add(tagItem);

                    if (resourceTag.sked__Expiry_Date__c != NULL) {
                        if (this.firstTagExpiry == NULL || this.firstTagExpiry < resourceTag.sked__Expiry_Date__c) {
                            this.firstTagExpiry = resourceTag.sked__Expiry_Date__c;
                        }
                    }
                }
            }
        }

        public void loadResourceScore(List<sked__Account_Resource_Score__c> resourceScores) {
            if (resourceScores != NULL && !resourceScores.isEmpty()) {
                sked__Account_Resource_Score__c resourceScore = resourceScores.get(0);
                this.accountResourceScore = new skedModels.accountResourceScore();
                this.accountResourceScore.whitelisted = resourceScore.sked__Whitelisted__c;
                this.accountResourceScore.blacklisted = resourceScore.sked__Blacklisted__c;
            }
        }
    }

    global virtual class region extends modelBase {
        public string timezoneSidId {get; set;}
    }

    global virtual class schedule extends modelBase {
        public string templateId {get; set;}
        public string description {get; set;}
        public boolean skipHolidays {get; set;}
        public template template {get; set;}
    }

    global virtual class serviceLocation extends modelBase {
        public string accountId {get; set;}
        public string regionId {get; set;}
        public string description {get; set;}
        public address address {get; set;}
    }

    global virtual class tag extends modelBase {
        public transient DateTime expiryTime {get; set;}
    }

    global virtual class template extends modelBase {
        public string startDate {get; set;}
        public string endDate {get; set;}
        public List<templateEntry> entries {get; set;}
    }

    global virtual class templateEntry extends modelBase {
        public integer weekNo {get; set;}
        public string weekday {get; set;}
        public integer startTime {get; set;}
        public integer endTime {get; set;}
    }

    /************************************************ SKEDULO CUSTOM MODELS ************************************************/
    global virtual class clientAvailability extends event {
        public string regionId {get; set;}
        public string patientId {get; set;}
        public string scheduleId {get; set;}
        public string serviceLocationId {get; set;}
        public string notes {get; set;}
        public string preferredStartDate {get; set;}
        public integer preferredStartTime {get; set;}
        public string preferredEndDate {get; set;}
        public integer preferredEndTime {get; set;}
    }

    global virtual class displaySetting extends modelBase {
        public integer availableEnd {get; set;}
        public integer availableStart {get; set;}
        public string backgroundColor {get; set;}
        public string color {get; set;}
        public string shiftType {get; set;}
        public boolean showLegend {get; set;}
    }

    global virtual class exceptionLog extends modelBase {
        public string exceptionCode {get; set;}
        public string caseNumber {get; set;}
        public string patientName {get; set;}
        public skedModels.job job {get; set;}
        public skedModels.resource resource {get; set;}
    }

    global virtual class groupAttendee extends modelBase {
        public string contactId {get; set;}
        public contact contact {get; set;}
        public string groupEventId {get; set;}
    }

    global virtual class groupEvent extends modelBase {
        public string accountId {get; set;}
        public modelBase account {get; set;}
        public string contactId {get; set;}
        public contact contact {get; set;}
        public string regionId {get; set;}
        public modelBase region {get; set;}
        public address address {get; set;}
        public string description {get; set;}
        public string status {get; set;}

        public list<groupAttendee> attendees {get; set;}
        public list<tag> tags {get; set;}
        public list<tag> excludedTags {get; set;}

        public groupEvent(sked_Group_Event__c groupEventEntity) {
            this.Id = groupEventEntity.Id;
            this.Name = groupEventEntity.Name;
            this.accountId = groupEventEntity.sked_Account__c;
            this.contactId = groupEventEntity.sked_Coordinator__c;
            this.regionId = groupEventEntity.sked_Region__c;
            this.description = groupEventEntity.sked_Description__c;
            this.status = groupEventEntity.sked_Status__c;
            this.address = new skedModels.address();
            this.address.fullAddress = groupEventEntity.sked_Address__c;
            this.address.geometry = new skedModels.geometry(groupEventEntity.sked_GeoLocation__c);
        }
    }

    global virtual class groupTag extends modelBase {
        public string groupEventId {get; set;}
        public string tagId {get; set;}
    }

    global virtual class jobAttendee extends modelBase {
        public boolean attended {get; set;}
        public decimal cancellationFee {get; set;}
        public string cancellationReason {get; set;}
        public string jobId {get; set;}
        public string contactId {get; set;}
        public string description {get; set;}
        
        public job job {get; set;}
        public contact contact {get; set;}
    }

    global virtual class jobOffer extends modelBase {
        public string jobId {get; set;}
        public string resourceId {get; set;}
        public string status {get; set;}
        public integer travelTimeFrom {get; set;}
        public decimal travelDistanceFrom {get; set;}
        public job job {get; set;}
        public resource resource {get;set;}
    }

    global virtual class patient extends modelBase {
    }

    global virtual class selectOption {
        public string id {get; set;}
        public string name {get; set;}
        public boolean selected {get; set;}

        public selectOption(string value, string text) {
            this.id = value;
            this.name = text;
            this.selected = false;
        }

        public selectOption(string value, string text, boolean selected) {
            this.id = value;
            this.name = text;
            this.selected = selected;
        }
    }

    global virtual class shiftTypeSetting extends displaySetting {
        public string objectType {get; set;}
        public boolean canBePreDated {get; set;}
        public boolean isAvailable {get; set;}
        public string shortName {get; set;}
        public integer step {get; set;}
    }

}