@isTest
public class SF_CountInviocesTest {
    @TestSetup
    static void makeData(){
        // This method creates Account, Contact, Opportunity and Quote
        SF_TestDataFactory.createBase();
        
        // Change status of quote to 'Accepted', which creates order and order products
        List<SF_Quote__c> q = [SELECT Id, Status__c FROM SF_Quote__c WHERE Status__c = 'Draft' LIMIT 1];
        q[0].Status__c = 'Accepted';
        update q;
        
    }
    @isTest
    public static void countInvoiceTest(){
        
        // Execute batch, which creates new Invoice
        Test.startTest();
        Id invoiceBatch = Database.executeBatch(new SF_CreateInvoice());
        Test.stopTest();
        
        // Check if the value of NO_Invoices__c field is increased 
        List<SF_Order__c> ord = [SELECT Id, NO_Invoices__c FROM SF_Order__c LIMIT 1];
        System.assertEquals(1, ord[0].NO_Invoices__c, 'Number of invoices is not correct');
        
    }
}