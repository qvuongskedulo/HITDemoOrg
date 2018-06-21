public class skedAdhocResourceTagMapper extends skedAdhocMapperBase {
	public override void execute(list<sObject> sourceRecords, list<sObject> targetRecords) {
        system.debug('#############################################################################################################');
        system.debug('################################ Enter custom adhoc mapper - skedAdhocResourceTagMapper. ####################');
        set<string> tags = new set<string>();
        for (sObject sourceRecord : sourceRecords) {
            tags.add((string)sourceRecord.get('HealthCloudGA__Code__c'));
        }
        
        list<sked__Tag__c> entityTags = [SELECT id, name FROM sked__Tag__c WHERE name IN :tags];
        Map<string, Id> tagNameIdMap = new Map<string, Id>();
        for (sked__Tag__c tag : entityTags) {
            tagNameIdMap.put(tag.name, tag.id);
        }

        list<sked__Tag__c> newEntityTags = new List<sked__Tag__c>();
        for (string tag : tags) {
            if (tagNameIdMap.get(tag) == null) {
                sked__Tag__c newEntityTag = new sked__Tag__c();
                newEntityTag.name = tag;
                newEntityTag.sked__Type__c = 'Skill';
                newEntityTag.sked__Classification__c = 'Human';

                newEntityTags.add(newEntityTag);
            }
        }

        if (newEntityTags.size() > 0) {
            insert newEntityTags;

            for (sked__Tag__c newEntityTag : newEntityTags) {
                tagNameIdMap.put(newEntityTag.name, newEntityTag.Id);
            }
        }

        Map<Id, Id> practitionerToTagMap = new Map<Id, Id>();
        for (sObject sourceRecord : sourceRecords) {
            string ehrCode = (string)sourceRecord.get('HealthCloudGA__Code__c');
            if (!string.isBlank(ehrCode)) {
                practitionerToTagMap.put((Id)sourceRecord.get('Id'), tagNameIdMap.get(ehrCode));
            }
        }

        for (sObject targetRecord : targetRecords) {
            targetRecord.put('sked__Tag__c', practitionerToTagMap.get((Id)targetRecord.get('sked_EHR_Practitioner_Qualification__c')));
        }
        system.debug('################################# Endcustom adhoc mapper - skedAdhocResourceTagMapper.######################');
    }
}