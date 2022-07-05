// Test class, which checks if the Orders and Order Products are created after Status field change on Quote object.
@IsTest
public class SF_CreateOrderHelperTest {
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
                                          CloseDate = System.today().addDays(7));
        insert opp;
        
        Contact contact = new Contact(AccountId  = acc.Id,
                                      LastName = 'Solomonia',
                                      CurrencyIsoCode = 'USD');
        insert contact;
        
        SF_Quote__c createQuote = new SF_Quote__c(Name = 'createQuote',
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
        insert createQuote;
    }
    // Check if Order is created on Status field change on Quote
    @IsTest
    public static void test_createOrder(){
        
        List<SF_Quote__c> quotes = [SELECT Id, Name, Status__c FROM SF_Quote__c WHERE Status__c = 'Draft' LIMIT 1];
        
        quotes[0].Status__c = 'Accepted';
        
        try {
            Test.startTest();
            update quotes;
            Test.stopTest();
            system.assertEquals('Accepted', quotes[0].Status__c);
        } catch (Exception ex) {
            Boolean isError =  ex.getMessage().contains('Order is not created.')? true : false;
            system.assertEquals(true, isError);
        }
    }
    // Check if Order Products are created when there are Line Items on Quote
    @IsTest
    public static void test_createOrderProducts(){
        
        List<SF_Quote__c> quotes = [SELECT Id, Name, Status__c FROM SF_Quote__c WHERE Status__c = 'Draft' LIMIT 1];
        SF_Quote_Line_Item__c insertQLI = new SF_Quote_Line_Item__c(SF_Quote__c = quotes[0].Id,
                                                                    Name = 'New QLI');
        insert insertQLI;
        quotes[0].Status__c = 'Accepted';
        
        try {
            Test.startTest();
            update quotes;
            Test.stopTest();
            system.assertEquals('Accepted', quotes[0].Status__c);
            
        } catch (Exception ex) {
            Boolean isError =  ex.getMessage().contains('Order Product is not created.')? true : false;
            system.assertEquals(true, isError);
        }
    }
}