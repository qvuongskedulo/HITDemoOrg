public class skedSyncActions {
    
    public class insertAction extends skedSyncActionBase {
        public insertAction(skedTriggerContainer.triggerContext triggerContext) {
            this.triggerContext = triggerContext;
        }

        public override void doMapping() {
            map<string, List<sObject>> insertedSObjects = this.mapper.execute(triggerContext.newRecords);

            List<sObject> outputSObjects = new List<sObject>();
            for (list<sObject> sObjectTypeItems : insertedSObjects.values()) {
                outputSObjects.addAll(sObjectTypeItems);
            }

            insert outputSObjects;
        }
    }
    
    public class updateAction extends skedSyncActionBase {
        public updateAction(skedTriggerContainer.triggerContext triggerContext) {
            this.triggerContext = triggerContext;
        }
        
        public override void doMapping() {
            map<string, List<sObject>> updatedSObjects = this.mapper.execute(triggerContext.newRecords);
            list<sObject> insertRecords = new List<sObject>();
            list<sObject> updateRecords = new List<sObject>();
            
            for (list<sObject> sObjectTypeItems : updatedSObjects.values()) {
                for (sObject record : sObjectTypeItems) {
                    if (record.get('Id') == null) {
                        insertRecords.add(record);
                    }
                    else {
                        updateRecords.add(record);
                    }
                }
            }

            insert insertRecords;
            update updateRecords;
        }
    }
    
    public class deleteAction extends skedSyncActionBase {
        public deleteAction(skedTriggerContainer.triggerContext triggerContext) {
            this.triggerContext = triggerContext;
        }
        
        public override void doMapping() {
            List<sObject> existedRecords = new List<sObject>();
            set<Id> inputRecordIds = new set<Id>();
            for (sObject record : this.triggerContext.newRecords) {
                inputRecordIds.add((Id) record.get('Id'));
            }

            for (skedObjectMapper.objectMappingModel objectMappingItem : mapper.getObjectMappings()) {
                string queryStatement = '';
                queryStatement += ' SELECT Id ';
                queryStatement += ' FROM ' + objectMappingItem.targetSObject;
                queryStatement += ' WHERE ' + objectMappingItem.targetSObjectIdentifyField + ' IN :inputRecordIds';

                existedRecords.addAll((List<sObject>)Database.query(queryStatement));
            }

            delete existedRecords;
        }
    }

}