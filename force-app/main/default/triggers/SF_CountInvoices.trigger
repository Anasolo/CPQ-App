// This trigger is counting the number of invoices and stores in Order's field Number Of Invoices
// When Invoice is created, field value has to increase
trigger SF_CountInvoices on SF_Invoice__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        SF_CountInvoicesHandler.numOfInvoices(Trigger.new);
    }
}