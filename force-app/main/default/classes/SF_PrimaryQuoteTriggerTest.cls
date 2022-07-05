@IsTest
public class SF_PrimaryQuoteTriggerTest {
    @TestSetup
    static void makeData(){

        Account acc = new Account(Name = 'quoteTriggerAcc',
                                  Billing_Country__c = 'Georgia',
                                  Billing_Postal_Code__c = '0177',
                                  Billing_State__c = 'None',
                                  Billing_Street__c = 'Kazbegi',
                                  CurrencyIsoCode = 'USD',
                                  Account_Location__c = 'Georgia');
        
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'quoteTriggerOpp',
                                          StageName = 'Prospecting',
                                          CurrencyIsoCode = 'USD',
                                          Account__c = acc.Id,
                                          CloseDate = System.today());
        insert opp;
    }
    // test while creating first quote on opportunity (has to create quote with primary true)
    @IsTest
    public static void firstQuoteIsPrimary(){

        Opportunity opptyId = [SELECT Id FROM Opportunity LIMIT 1];
        
        SF_Quote__c createQuote = new SF_Quote__c(Name = 'createQuote',
                                                  Opportunity__c = opptyId.Id,
                                                  Expiration_Date__c = System.today());
        
        Test.startTest();
        insert createQuote;
        Test.stopTest();
        
        SF_Quote__c result = [SELECT Primary__c FROM SF_Quote__c WHERE Opportunity__c=:opptyId.Id];
        
        System.assert(result.Primary__c != false, 'First quote must be primary!');
        
    }
    // when primary quote already exists and user adds new one, uncheck previous primary quote
    @isTest
    public static void newPrimaryOnInsert() {

        Opportunity opptyId = [SELECT Id FROM Opportunity LIMIT 1];
        
        SF_Quote__c oldPrimaryQuote = new SF_Quote__c(Name = 'oldPrimaryQuote',
                                                      Opportunity__c = opptyId.Id,
                                                      Primary__c = true,
                                                      Status__c = 'Draft',
                                                      Expiration_Date__c = System.today());
        
        insert oldPrimaryQuote;
        
        SF_Quote__c newPrimaryQuote = new SF_Quote__c(Name = 'newPrimaryQuote',
                                                      Opportunity__c = opptyId.Id,
                                                      Primary__c = true,
                                                      Status__c = 'Approved',
                                                      Expiration_Date__c = System.today());
        
        Test.startTest();
        insert newPrimaryQuote;
        Test.stopTest();
        
        List<SF_Quote__c> result = [SELECT Primary__c FROM SF_Quote__c WHERE Status__c = 'Draft' LIMIT 1];
        
        System.assertEquals(false, result[0].Primary__c);
    }
    // when user changes primary status on existing quotes, check selected and uncheck previous quote
    @isTest
    public static void updateQuotetoPrimary() {

        Opportunity opptyId = [SELECT Id FROM Opportunity LIMIT 1];
        
        SF_Quote__c nonPrimaryQuote = new SF_Quote__c(Name = 'nonPrimaryQuote',
                                                      Opportunity__c = opptyId.Id,
                                                      Primary__c = false,
                                                      Status__c = 'Approved',
                                                      Expiration_Date__c = System.today());
        
        insert nonPrimaryQuote;
        
        SF_Quote__c newPrimaryQuote = new SF_Quote__c(Name = 'newPrimaryQuote',
                                                      Opportunity__c = opptyId.Id,
                                                      Primary__c = true,
                                                      Expiration_Date__c = System.today());
        
        insert newPrimaryQuote;
        
        nonPrimaryQuote.Primary__c = true;
        
        Test.startTest();
        update nonPrimaryQuote;
        Test.stopTest();
        
        List<SF_Quote__c> result = [SELECT Primary__c FROM SF_Quote__c WHERE Status__c = 'Approved' LIMIT 1];
        
        System.assertEquals(true, result[0].Primary__c);
    }

   // user is not allowed to uncheck primary quote
   @isTest
    static void uncheckIsNotAllowed(){

      Opportunity opptyId = [SELECT Id FROM Opportunity LIMIT 1];

      SF_Quote__c primaryQuote = new SF_Quote__c(Name = 'primaryQuote',
                                                 Opportunity__c = opptyId.Id,
                                                 Primary__c = true,
                                                 Status__c = 'Draft',
                                                 Expiration_Date__c = System.today());

      insert primaryQuote;
                
      primaryQuote.Primary__c = false;

      try {
         Test.startTest();
         update primaryQuote;
         Test.stopTest();
      } catch (Exception ex) {
         Boolean isError =  ex.getMessage().contains('You can not uncheck Primary field.')? true : false;
         system.assertEquals(true, isError);
      }
    
    }
   // user is not allowed to delete primary quote
   @isTest
   static void deleteIsNotAllowed(){
      Opportunity opptyId = [SELECT Id FROM Opportunity LIMIT 1];
      
      SF_Quote__c primaryQuote = new SF_Quote__c(Name = 'nonPrimaryQuote',
                                                    Opportunity__c = opptyId.Id,
                                                    Primary__c = true,
                                                    Expiration_Date__c = System.today());
      
      insert primaryQuote;
      
      Test.startTest();
      try {
         delete primaryQuote;
      } catch (Exception ex) {
         Boolean isError =  ex.getMessage().contains('Cant delete Primary quote. Please select another quote as Primery and then delete this one') ? true : false;
         System.assertEquals(isError, false,'Single Primary quote cant be deleted');
      }
      Test.stopTest();
   }

}