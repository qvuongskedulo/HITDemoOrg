public virtual class skedTriggerCentralizationHandler {

    public enum QueryContext {QUERY_BASE, QUERY_DATA_BEFORE, QUERY_DATA_AFTER}
    public List<SObject> Records { get; private set; }

    public skedTriggerCentralizationHandler(List<SObject> sObjectList) {
        Records = sObjectList;
    }

    // --------------------------------------------------------------------------------------------------------------------
    // Virtual Methods
    // --------------------------------------------------------------------------------------------------------------------

    /* @Desc: Override this to invoke base logic in the before insert phase, this is called by the handleBeforeInsertBase method */
    public virtual void onBeforeInsertBase() { }

    /* @Desc: Override this to invoke base logic in the before update phase, this is called by the handleBeforeUpdateBase method */
    public virtual void onBeforeUpdateBase(Map<Id, SObject> mapOldRecords) { }

    /* @Desc: Override this to invoke base logic in the before delete phase, this is called by the handleBeforeDeleteBase method */
    public virtual void onBeforeDeleteBase() { }

    /* @Desc: Override this to invoke base logic in the after insert phase, this is called by the handleAfterInsertBase method */
    public virtual void onAfterInsertBase() { }

    /* @Desc: Override this to invoke base logic in the after update phase, this is called by the handleAfterUpdateBase method */
    public virtual void onAfterUpdateBase(Map<Id, SObject> mapOldRecords) { }

    /* @Desc: Override this to invoke base logic in the after delete phase, this is called by the handleAfterDeleteBase method */
    public virtual void onAfterDeleteBase() { }

    /* @Desc: Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method */
    public virtual void onBeforeInsert() { }

    /* @Desc: Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method */
    public virtual void onBeforeUpdate(Map<Id, SObject> mapOldRecords) { }

    /* @Desc: Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method */
    public virtual void onBeforeDelete() { }

    /* @Desc: Override this to perform processing during the after insert phase, this is called by the handleAfterInsert method */
    public virtual void onAfterInsert() { }

    /* @Desc: Override this to perform processing during the after update phase, this is called by the handleAfterUpdate method */
    public virtual void onAfterUpdate(Map<Id, SObject> mapOldRecords) { }

    /* @Desc: Override this to perform processing during the after delete phase, this is called by the handleAfterDelete method */
    public virtual void onAfterDelete() { }

    /* @Desc: Override this to perform processing during the after Undelete phase, this is called by the handleAfterUDelete method */
    public virtual void onAfterUndelete() { }

    // --------------------------------------------------------------------------------------------------------------------
    // Base Action
    // --------------------------------------------------------------------------------------------------------------------

    /**
     * @Desc: Base handler for the Apex Trigger event Before Insert, calls the onBeforeInsertBase method
     */
    public void handleBeforeInsertBase() {
        onBeforeInsertBase();
    }

    /**
     * @Desc: Base handler for the Apex Trigger event After Insert, calls the onAfterInsertBase method
     **/
    public void handleAfterInsertBase() {
        onAfterInsertBase();
    }

    /**
     * @Desc: Base handler for the Apex Trigger event Before Update, calls the onBeforeUpdateBase method
     **/
    public void handleBeforeUpdateBase(Map<Id, SObject> mapOldRecords) {
        onBeforeUpdateBase(mapOldRecords);
    }

    /**
     * @Desc: Base handler for the Apex Trigger event After Update, calls the onAfterUpdateBase method
     **/
    public void handleAfterUpdateBase(Map<Id, SObject> mapOldRecords) {
        onAfterUpdateBase(mapOldRecords);
    }

    /**
     * @Desc: Base handler for the Apex Trigger event Before Delete, calls the onBeforeDeleteBase method
     **/
    public void handleBeforeDeleteBase() {
        onBeforeDeleteBase();
    }

    /**
     * @Desc: Base handler for the Apex Trigger event After Delete, calls the onAfterDeleteBase method
     **/
    public void handleAfterDeleteBase() {
        onAfterDeleteBase();
    }

    // --------------------------------------------------------------------------------------------------------------------
    // Regular Action
    // --------------------------------------------------------------------------------------------------------------------

    /**
     * @Desc: Handler for the Apex Trigger event Before Insert, calls the onBeforeInsert method
     */
    public void handleBeforeInsert() {
        onBeforeInsert();
    }

    /**
     * @Desc: Handler for the Apex Trigger event After Insert, calls the onAfterInsert method
     **/
    public void handleAfterInsert() {
        System.debug(LoggingLevel.INFO, 'TriggerHandler.handleAfterInsert()');
        onAfterInsert();
    }

    /**
     * @Desc: Handler for the Apex Trigger event Before Update, calls the onBeforeUpdate method
     **/
    public void handleBeforeUpdate(Map<Id, SObject> mapOldRecords) {
        onBeforeUpdate(mapOldRecords);
    }

    /**
     * @Desc: Handler for the Apex Trigger event After Update, calls the onAfterUpdate method
     **/
    public void handleAfterUpdate(Map<Id, SObject> mapOldRecords) {
        onAfterUpdate(mapOldRecords);
    }

    /**
     * @Desc:Base Handler for the Apex Trigger event Before Delete, calls the onBeforeDelete method
     **/
    public void handleBeforeDelete() {
        onBeforeDelete();
    }

    /**
     * @Desc: Handler for the Apex Trigger event After Delete, calls the onAfterDelete method
     **/
    public void handleAfterDelete() {
        onAfterDelete();
    }

// --------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc:  Interface to be implemented by 'Constructor' class in specific object handler; allows class to be dynamically instantiated
     **/
    public interface IConstructable {
        skedTriggerCentralizationHandler construct(List<SObject> sObjectList);
    }

//  --------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc: Method constructs the given Domain class with the current
     * Trigger context before calling the applicable override methods
     * such as beforeInsert, beforeUpdate etc.
     */
    public static void processTriggerHandler(Type objectHandlerClass, Type queryHandlerClass) {

        // Process specific object handler
        processTriggerHandler(
            objectHandlerClass,
            queryHandlerClass,
            Trigger.isBefore,
            Trigger.isAfter,
            Trigger.isInsert,
            Trigger.isUpdate,
            Trigger.isDelete,
            Trigger.new,
            Trigger.oldMap);
    }

//  --------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc: Handles the queries by calling the QueryHandlerClass passed in the parameters
     **/
    private static void executeQueries(Type queryHandlerClass, QueryContext operationContext, List<SObject> listSObjects) {
        if (queryHandlerClass != null) {
            // Create an instance of the query handler class
            //TriggerQueryHandler queryHandler = (TriggerQueryHandler) queryHandlerClass.newInstance();
            //if (operationContext == TriggerObjectHandler.QueryContext.QUERY_BASE) {
            //    queryHandler.queryBase(listSObjects);
            //} else if (operationContext == TriggerObjectHandler.QueryContext.QUERY_DATA_BEFORE) {
            //    queryHandler.queryDataBeforeAction(listSObjects);
            //} else if (operationContext == TriggerObjectHandler.QueryContext.QUERY_DATA_AFTER) {
            //    queryHandler.queryDataAfterAction(listSObjects);
            //}

        }
    }

//  --------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc: Calls the applicable override methods such as beforeInsert, beforeUpdate etc. based on a Trigger context
     */
    private static void processTriggerHandler(
        Type objectHandlerClass,
        Type queryHandlerClass,
        Boolean isBefore,
        Boolean isAfter,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        List<SObject> newRecords,
        Map<Id, SObject> oldRecordsMap
    ) {
        // Pass the object handler class to the ComponentControl, this will determine if triggers are active for the given handler
        //Boolean isTriggerActive = ComponentControl.isComponentEnabled(objectHandlerClass, 'TriggerHandlerCore');

        // Construct the domain class constructor class
        String domainClassName = objectHandlerClass.getName();
        Type constructableClass = domainClassName.endsWith('Constructor') ? Type.forName(domainClassName) : Type.forName(domainClassName + '.Constructor');
        IConstructable handlerConstructor = (IConstructable) constructableClass.newInstance();

        // Instantiate a Boolean and determine whether batch of objects has been processed by the handler
        Boolean isBatchProcessed = FALSE;

        if (isUpdate) {
            for (sObject sObj : newRecords) {
                //if (ComponentControl.isObjectProcessed(objectHandlerClass, sObj)) {
                //    isBatchProcessed = TRUE;
                //    break;
                //}
            }
        }

        // Get Context / Operation to output to log
        String context = isBefore ? 'Before' : 'After';
        String operation = isInsert ? 'Insert' : (isUpdate ? 'Update' : 'Delete');

        System.debug(LoggingLevel.INFO, 'Executing Object Handler Logic for: ' + objectHandlerClass.getName() + ' in ' + context + '-' + operation);
        //System.debug(LoggingLevel.INFO, objectHandlerClass.getName() + ' Triggers are Active: ' + isTriggerActive);
        //System.debug(LoggingLevel.INFO, objectHandlerClass.getName() + ' Batch is Processed: ' + isBatchProcessed);

        // Invoke query base logic. This will run on before & after action
        if (isInsert || isUpdate) {
            executeQueries(queryHandlerClass, QueryContext.QUERY_BASE, newRecords);
        } else if (isDelete) {
            executeQueries(queryHandlerClass, QueryContext.QUERY_BASE, oldRecordsMap.values());
        }

        // Execute the appropriate QueryHandler / ObjectHandler methods
        if (isBefore) {

            if (isInsert) {
                handlerConstructor.construct(newRecords).handleBeforeInsertBase();
            } else if (isUpdate) {
                handlerConstructor.construct(newRecords).handleBeforeUpdateBase(oldRecordsMap);
            } else if (isDelete) {
                handlerConstructor.construct(oldRecordsMap.values()).handleBeforeDeleteBase();
            }

            //if (isTriggerActive) {
            //    if (isInsert) {
            //        executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_BEFORE, newRecords);
            //        handlerConstructor.construct(newRecords).handleBeforeInsert();
            //    } else if (isUpdate) {
            //        if (!isBatchProcessed) {
            //            executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_BEFORE, newRecords);
            //            handlerConstructor.construct(newRecords).handleBeforeUpdate(oldRecordsMap);
            //        }
            //    } else if (isDelete) {
            //        executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_BEFORE, oldRecordsMap.values());
            //        handlerConstructor.construct(oldRecordsMap.values()).handleBeforeDelete();
            //    }
            //}
        } else {

            if (isInsert) {
                handlerConstructor.construct(newRecords).handleAfterInsertBase();
            } else if (isUpdate) {
                handlerConstructor.construct(newRecords).handleAfterUpdateBase(oldRecordsMap);
            } else if (isDelete) {
                handlerConstructor.construct(oldRecordsMap.values()).handleAfterDeleteBase();
            }

            //if (isTriggerActive) {
            //    if (isInsert) {
            //        executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_AFTER, newRecords);
            //        handlerConstructor.construct(newRecords).handleAfterInsert();
            //        //ComponentControl.setObjectsProcessed(objectHandlerClass, newRecords);
            //    } else if (isUpdate) {
            //        if (!isBatchProcessed) {
            //            executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_AFTER, newRecords);
            //            handlerConstructor.construct(newRecords).handleAfterUpdate(oldRecordsMap);
            //            ComponentControl.setObjectsProcessed(objectHandlerClass, newRecords);
            //        }
            //    } else if (isDelete) {
            //        executeQueries(queryHandlerClass, QueryContext.QUERY_DATA_AFTER, oldRecordsMap.values());
            //        handlerConstructor.construct(oldRecordsMap.values()).handleAfterDelete();
            //    }
            //}
        }

    }
}