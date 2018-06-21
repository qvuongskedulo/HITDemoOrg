trigger skedCaseTrigger on Case (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('Case');
}