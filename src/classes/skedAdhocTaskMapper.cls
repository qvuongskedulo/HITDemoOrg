public class skedAdhocTaskMapper extends skedAdhocMapperBase {
    public override void execute(list<sObject> sourceRecords, list<sObject> targetRecords) {
        RecordType recordType = [SELECT id FROM RecordType WHERE Name = :skedConstants.CARE_PLAN_RECORD_TYPE][0];
        for (sObject targetRecord : targetRecords) {
            sObject matchedRecord;
            for (sObject sourceRecord : sourceRecords) {
                if ((Id)targetRecord.get('sked_Job_Allocation__c') == (Id) sourceRecord.get('Id')) {
                    matchedRecord = sourceRecord;
                }
            }
            targetRecord.put('ActivityDate', ((sked__Job_Allocation__c)matchedRecord).sked__Job__r.sked__Start__c.Date());
            targetRecord.put('RecordTypeId', recordType.Id);
        }
    }
}