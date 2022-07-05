@isTest
public class SF_CreateInvoiceTest {
    @TestSetup
    static void makeData(){
        
        Product2 product = new Product2(Name='Macbook');
        insert product;
        
        SF_Price_List__c pl = new SF_Price_List__c(Name='USD Price List');
        insert pl;
        
        SF_Price_List_Item__c pli = new SF_Price_List_Item__c(SF_Price_List__c=pl.Id, Product__c=product.Id);
        insert pli;
        
        Account acc = new Account(Name = 'quoteTriggerAcc',
                                  Billing_Country__c = 'Georgia',
                                  Billing_Postal_Code__c = '0177',
                                  Billing_State__c = 'None',
                                  Billing_Street__c = 'Kazbegi',
                                  CurrencyIsoCode = 'USD',
                                  Account_Location__c = 'Georgia');        
        insert acc;
        
        Contact contact = new Contact(AccountId  = acc.Id,
                                      LastName = 'Solomonia',
                                      CurrencyIsoCode = 'USD');
        insert contact;
        
        Opportunity opp = new Opportunity(Name = 'InvoiceTest',
                                          StageName = 'Prospecting',
                                          CurrencyIsoCode = 'USD',
                                          Account__c = acc.Id,
                                          CloseDate = System.today().addDays(7));
        insert opp;
        
        SF_Quote__c quote = new SF_Quote__c(Name = 'createQuote',
                                            Status__c = 'Draft',
                                            Account__c = acc.Id,
                                            Contact__c = contact.Id,
                                            Billing_Country__c = 'Georgia',
                                            Billing_Postal_Code__c = '0177',
                                            Billing_State__c = 'None',
                                            Billing_Street__c = 'Kazbegi',
                                            Shipping_Country__c = 'Georgia',
                                            Shipping_Postal_Code__c = '0177',
                                            Shipping_State__c = 'None',
                                            Shipping_Street__c = 'Kazbegi',
                                            Opportunity__c = opp.Id,
                                            Expiration_Date__c = System.today().addDays(7));
        insert quote;
        
        SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c(Name='Book', SF_Quote__c=quote.Id,Product__c=product.Id);
        insert qli;
       
		List<SF_Quote__c> q = [SELECT Id, Status__c FROM SF_Quote__c WHERE Status__c = 'Draft' LIMIT 1];
        q[0].Status__c = 'Accepted';
        update q;
    }
    @isTest
    public static void createInvoiceTest(){
        List<SF_Order__c> order = [SELECT Id, Name, NO_Invoices__c FROM SF_Order__c LIMIT 1];
        
        Test.startTest();
        Id invoiceBatch = Database.executeBatch(new SF_CreateInvoice());
        Test.stopTest();
        
        List<SF_Invoice__c> inv = [SELECT Id, Order__c FROM SF_Invoice__c WHERE Order__c = :order[0].Id];
        System.assertEquals(false, inv.isEmpty(), 'Invoice was not created');
    }
}