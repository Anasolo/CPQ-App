@IsTest
public class SF_CloneQuoteTest {
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
        
        SF_Quote__c createQuote = new SF_Quote__c(Name = 'createQuote',
                                                  Opportunity__c = opp.Id,
                                                  Status__c = 'Draft',
                                                  Expiration_Date__c = System.today());
        insert createQuote;
    }
    @IsTest
    public static void cloneQuoteTest(){
        
        
        List<Opportunity> opptyId = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<SF_Quote__c> quote = [SELECT Id FROM SF_Quote__c WHERE Opportunity__c=:opptyId[0].Id AND Status__c = 'Draft' LIMIT 1];
        
        SF_CloneQuoteWrapper wrapper = new SF_CloneQuoteWrapper();
        wrapper.quoteId = quote[0].Id;
        wrapper.includeQLI = true;
        List<SF_CloneQuoteWrapper> wr = new List<SF_CloneQuoteWrapper>();
        wr.add(wrapper);
        
        Test.startTest();
       	List<SF_Quote__c> quotes = SF_CloneQuote.cloneQuote(wr);
        Test.stopTest();
        
        System.assert(quotes != null, 'Quote was not clonned');
        
    }
}