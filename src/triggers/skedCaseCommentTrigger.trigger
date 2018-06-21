trigger skedCaseCommentTrigger on CaseComment (after insert, after update) {
    skedTriggerContainer container = new skedTriggerContainer();
    container.execute('CaseComment');
}