@isTest
public class SF_PostInvoiceTest {
    @TestSetup
    public static void makeData(){
        Account acc = new Account(Name = 'quoteTriggerAcc',
                                  Billing_Country__c = 'Georgia',
                                  Billing_Postal_Code__c = '0177',
                                  Billing_State__c = 'None',
                                  Billing_Street__c = 'Kazbegi',
                                  CurrencyIsoCode = 'USD',
                                  Account_Location__c = 'Georgia');
        
        insert acc;
        
        SF_Invoice__c invoice = new SF_Invoice__c(Account__c = acc.Id,
                                                  Status__c = 'Draft',
                                                  Invoice_Date__c = System.today() + 1);
        
        insert invoice;
    }
    @isTest
    public static void postInvoiceTest(){
        
        Test.startTest();
        SF_PostInvoice invoiceBatch = new SF_PostInvoice();
        Database.executeBatch(invoiceBatch);
        Test.stopTest();
        SF_Invoice__c inv = [SELECT Id, Status__c, Invoice_Date__c FROM SF_Invoice__c LIMIT 1 ];
        
        System.assertEquals('Posted', inv.Status__c, 'Invoice is not posted');
    }
}