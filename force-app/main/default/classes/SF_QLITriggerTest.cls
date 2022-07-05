//comments
@isTest
public class SF_QLITriggerTest {
	@testSetup
    public static void createData() {
        Account acc = new Account(Name = 'Test Account', Account_Location__c = 'United States');
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', Account__c = acc.Id, closeDate = System.today().addDays(15), stageName = 'Prospecting');
        insert opp;
        
        SF_Price_List__c pl = new SF_Price_List__c(Name = 'USD Price List');
        insert pl;
        
        Product2 product = new Product2(Name = 'Test Product', Is_Bundle__c = true);
        insert product;
        
        SF_Price_List_Item__c pli = new SF_Price_List_Item__c(SF_Price_List__c = pl.Id, Product__c = product.Id, Base_Price__c = 35000);
        insert pli;
        
        SF_Quote__c quote = new SF_Quote__c(Name = 'Test Quote', Account__c = acc.Id, Opportunity__c = opp.Id, Expiration_Date__c = Date.today().addDays(25));
        insert quote;
    }
    
    @isTest
    public static void qliTriggerTest() {
        List<SF_Quote__c> quote = [SELECT Id FROM SF_Quote__c LIMIT 1];
        List<Product2> product = [SELECT Id, Name, Description__c, Is_Bundle__c FROM Product2 WHERE Name = 'Test Product'];
        List<SF_Price_List_Item__c> pli = [SELECT Id, Base_Price__c FROM SF_Price_List_Item__c LIMIT 1];
        
        if(quote.size() > 0 && product.size() > 0 && pli.size() > 0) {
             SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c(Name = 'Test Quote Line Item ', SF_Quote__c = quote[0].Id, Product__c = product[0].Id, SF_Price_List_Item__c = pli[0].Id);
             Test.startTest();
            	insert qli;
             Test.stopTest();
            
        	List<SF_Quote_Line_Item__c> updatedQlis = [SELECT Id, Name, List_Item_Description__c, Is_Bundle__c, List_Price__c, Unit_Price__c FROM SF_Quote_Line_Item__c LIMIT 5];
        	//check for one qli
        	if(updatedQlis.size() > 0) {
                System.assertEquals(product[0].Name, updatedQlis[0].Name, 'Names field value is incorrect');
        		System.assertEquals(product[0].Description__c, updatedQlis[0].List_Item_Description__c, 'Description is incorrect');
        		System.assertEquals(product[0].Is_Bundle__c, updatedQlis[0].Is_Bundle__c, 'Is Bundle is incorrect');
        		System.assertEquals(pli[0].Base_Price__c, updatedQlis[0].List_Price__c, 'List Price is incorrect');	
        		System.assertEquals(pli[0].Base_Price__c, updatedQlis[0].Unit_Price__c, 'Unit Price is incorrcet');
        	}
        }
	}
}