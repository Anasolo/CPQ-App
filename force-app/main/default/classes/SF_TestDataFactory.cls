@isTest
public with sharing class SF_TestDataFactory {
    @isTest
    // this method creates Account, Contact, Opportunity and Quote
    public static void createBase() {
        Account acc = new Account(Name = 'Test Account',
                                  Billing_Country__c = 'Georgia',
                                  Billing_Postal_Code__c = '0177',
                                  Billing_State__c = 'None',
                                  Billing_Street__c = 'Kazbegi',
                                  CurrencyIsoCode = 'USD',
                                  Account_Location__c = 'Georgia');        
        insert acc;
        
        Opportunity opp = new Opportunity (Name = 'InvoiceTest',
                                           StageName = 'Prospecting',
                                           CurrencyIsoCode = 'USD',
                                           Account__c = acc.Id,
                                           CloseDate = System.today().addDays(7));
        insert opp;
        
        Contact contact = new Contact(AccountId  = acc.Id,
                                      LastName = 'Solomonia',
                                      CurrencyIsoCode = 'USD');
        insert contact;
        
        SF_Quote__c quote = new SF_Quote__c (Name = 'createQuote',
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
    }
}