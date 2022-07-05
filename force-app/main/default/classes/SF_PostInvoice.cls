// 1 day before invoice date, status field must change to 'Posted'
public class SF_PostInvoice implements Database.Batchable<sObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Status__c, Invoice_Posted_Date__c
                                         FROM SF_Invoice__c
                                         WHERE (Invoice_Date__c = :System.today() + 1
                                                OR Invoice_Date__c < :System.today() + 1)
                                         AND Status__c = 'Draft']);
    }
    public void execute(Database.BatchableContext bc, List<SF_Invoice__c> invoices){
        for(SF_Invoice__c inv: invoices){
            inv.Status__c = 'Posted';
            inv.Invoice_Posted_Date__c = System.today();
        }
        update invoices;
    }
    public void finish(Database.BatchableContext bc){
    }
    public void execute (SchedulableContext SC) {
        Database.executeBatch(new SF_PostInvoice());
    }
}