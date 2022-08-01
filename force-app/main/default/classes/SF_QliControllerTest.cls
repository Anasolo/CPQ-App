/**
* ============================================
* @claseName: SF_QliControllerTest
* @description: This class tests SF_LookUpController
* @author: Jubo M.
* @Class: SF_QliController
* @dateCreated: 24/06/2022
* @lastChange: 24/06/2022 by Jubo M.
* ============================================ 
*/
@isTest
public with sharing class SF_QliControllerTest {
   @testSetup
   public static void makeData() {
    SF_Price_List__c pl = new SF_Price_List__c(Name='USD Price List', Active__c=true, CurrencyIsoCode='USD');

    insert pl;

    Account acc = new Account(Name='Test Account', Account_Location__c='United States', Billing_Country__c='United Sates', Billing_State__c='MN', Billing_Street__c='145th St NW Elk River', Billing_Postal_Code__c='18590', Shipping_Country__c='United Sates', Postal_Code__c='18590', Shipping_State__c='MN', Shipping_Street__c='145th St NW Elk River', Price_List__c=pl.Id);

    insert acc;

    Opportunity opp = new Opportunity(Name='Test Opportunity', AccountId=acc.Id, Account__c=acc.Id, CurrencyIsoCode='USD', SF_Price_List__c = pl.Id, CloseDate = System.today().addDays(28), StageName='Qualification');

    insert opp;

    SF_Quote__c quote = new SF_Quote__c(Name='Test Quote', Opportunity__c = opp.Id, Account__c=acc.Id, SF_Price_List__c = pl.Id, Expiration_Date__c = System.today().addDays(20), CurrencyIsoCode = 'USD');

    insert quote;

    Product2 product = new Product2(Name='Test Product', Is_Bundle__c = true);

    insert product;

    Product2 optionProduct = new Product2(Name='Test Option Product', Is_Bundle__c = false);

    insert optionProduct;

    SF_Price_List_Item__c pli = new SF_Price_List_Item__c(Active__c = true, Base_Price__c = 2000, SF_Price_List__c = pl.Id, Product__c = product.Id, CurrencyIsoCode = 'USD');

    insert pli;
       
   SF_Price_List_Item__c pli2 = new SF_Price_List_Item__c(Active__c = true, Base_Price__c = 100, SF_Price_List__c = pl.Id, Product__c = optionProduct.Id, CurrencyIsoCode = 'USD');

    insert pli2;

    SF_Quote_Line_Item__c qli = new SF_Quote_Line_Item__c(Name = 'Test Quote Line Item', SF_Quote__c = quote.Id, Product__c = product.Id, SF_Price_List_Item__c = pli.Id, Quantity__c = 1, Is_Bundle__c	= true);

    insert qli;

    SF_Quote_Line_Item__c qli2 = new SF_Quote_Line_Item__c(Name = 'Test Quote Line Item 2', Quote_Line_Item__c = qli.Id, SF_Quote__c = quote.Id, Product__c = optionProduct.Id, SF_Price_List_Item__c = pli.Id, Quantity__c = 1, Is_Bundle__c= false);

    insert qli2;
       
    SF_Quantity_Range__c bundleQr = new SF_Quantity_Range__c(Quantity_From__c = 1, Quantity_To__c = 10, Price_List_Item__c = pli.Id, Price__c = 100);
    insert bundleQr;
       
    SF_Quantity_Range__c opQr = new SF_Quantity_Range__c(Quantity_From__c = 1, Quantity_To__c = 10, Price_List_Item__c = pli2.Id, Price__c =  31);
    insert opQr;

   } 

   /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.getQlis method
    */ 
   @isTest
   public static void testGetQlis() {
    List<SF_Quote__c> quote = [SELECT Id FROM SF_Quote__c LIMIT 1];
    List<String> fieldNames = new List<String>();
    fieldNames.add('Name');
       
    System.assert(SF_QliController.getQlis(quote[0].Id, fieldNames).size() == 1, 'Qlis data was returned incorrectly');

   }

   /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.getFieldsLabelsMap method
    */ 
   @isTest static void testGetFieldsLabelsMap() {
        Map<String, Map<String, String>> fieldsInfoMap = SF_QliController.getFieldsLabelsMap();
        
        System.assert(fieldsInfoMap.keySet().size() > 0, 'Map with fields info was not created');
   }

   /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.getEditableFields method
    */ 
   @isTest static void testGetEditableFields() {
    List<String> fieldApiNames = SF_QliController.getEditableFields();
    
    System.assert(fieldApiNames.size() > 0, 'List was not created');
    }

    /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.insertQlisHappyPath method happy path
    */ 
    @isTest static void testInsertQlisHappyPath() {
        List<SF_Quote__c> quote = [SELECT Id FROM SF_Quote__c LIMIT 1];
        List<Product2> product = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        List<Product2> opProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Option Product'];
        List<SF_Price_List_Item__c> pli = [SELECT Id FROM SF_Price_List_Item__c WHERE Base_Price__c = 2000 LIMIT 1];
        List<SF_Price_List_Item__c> opPli = [SELECT Id FROM SF_Price_List_Item__c WHERE Base_Price__c = 100 LIMIT 1];

        Map<String, Map<String, String>> productIdQliInfoMap = new Map<String, Map<String, String>>();

        productIdQliInfoMap.put(product[0].Id, new Map<String, String>());
        productIdQliInfoMap.get(product[0].Id).put('quantity', '1');
        productIdQliInfoMap.get(product[0].Id).put('priceListItem', pli[0].Id);
        productIdQliInfoMap.get(product[0].Id).put('hasOptionalProducts', 'true');
        
        productIdQliInfoMap.put(opProduct[0].Id, new Map<String, String>());
        productIdQliInfoMap.get(opProduct[0].Id).put('quantity', '1');
        productIdQliInfoMap.get(opProduct[0].Id).put('priceListItem', opPli[0].Id);
        productIdQliInfoMap.get(opProduct[0].Id).put('hasOptionalProducts', 'false');
        
        System.debug('@@@@@@productIdQliInfoMap' + productIdQliInfoMap);

        Test.startTest();
        SF_QliController.insertQlis(productIdQliInfoMap, quote[0].Id);
        Test.stopTest();

        List<SF_Quote_Line_Item__c> qlis = [SELECT Id, SF_Quote__c FROM SF_Quote_Line_Item__c WHERE SF_Quote__c=:quote[0].Id];

        System.assert(qlis.size() > 0, 'Quote line items were not created at all or incorrect number of records  were created');
    }

    
    /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.updateQlis method
    */ 
    @isTest
    public static void testUpdateQlis() {
        List<SF_Quote_Line_Item__c> qli = [SELECT Id FROM SF_Quote_Line_Item__c WHERE Name = 'Test Product' LIMIT 1];

        List<Map<String, String>> qlisListMap = new List<Map<String, String>>();
        Map<String, String> qliFieldsValuesMap = new Map<String, String>();
        qliFieldsValuesMap.put('id', qli[0].Id);
        qliFieldsValuesMap.put('newValue', '10');

        qlisListMap.add(qliFieldsValuesMap);

        Test.startTest();
        SF_QliController.updateQlis(qlisListMap);
        Test.stopTest();


        List<SF_Quote_Line_Item__c> updatedQli = [SELECT Id, Quantity__c, Name FROM SF_Quote_Line_Item__c WHERE Name = 'Test Product' LIMIT 1];

        System.assertEquals(10, updatedQli[0].Quantity__c, 'Quote Line Item was not updated properly');
    }
    
     /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.cloneQli method
    */ 
    @isTest
    public static void testCloneQli() {
             
        List<SF_Quote__c> quote = [SELECT Id FROM SF_Quote__c LIMIT 1];
        List<Product2> product = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        List<SF_Price_List_Item__c> bundlePli = [SELECT Id FROM SF_Price_List_Item__c WHERE Base_Price__c = 2000 LIMIT 1];
        List<SF_Price_List_Item__c> optionPli = [SELECT Id FROM SF_Price_List_Item__c WHERE Base_Price__c = 100 LIMIT 1];
        
        List<SF_Quote_Line_Item__c> bundleQli = [SELECT Id, Name, Unit_Price__c, List_Price__c, Product__c FROM SF_Quote_Line_Item__c WHERE Name = 'Test Product' LIMIT 1];
		List<SF_Quote_Line_Item__c> optionQli = [SELECT Id, Name, Unit_Price__c, List_Price__c, Product__c FROM SF_Quote_Line_Item__c WHERE Name = 'Test Option Product' LIMIT 1];
        
        Map<String, String> bundleQliMap = new Map<String, String>();
       
        bundleQliMap.put('Id', bundleQli[0].Id);
 
        Map<String, String> optionQliMap = new Map<String, String>();
        
        optionQliMap.put('Id', optionQli[0].Id);
        
        List<Map<String, String>> optionQlisMapList = new List<Map<String, String>>();
        
        optionQlisMapList.add(optionQliMap);
        
        String successMessage = SF_QliController.cloneQli(bundleQliMap, optionQlisMapList);
        
        System.assertEquals(Label.cloneQliSuccessMessageLabel, successMessage);
    }
    
     /**
    * @author: Jubo M.
    * @description: This method tests SF_QliController.computePrices method
    */ 
    @isTest
    public static void testComputePrices() {
        List<SF_Quote_Line_Item__c> bundleQli = [SELECT Id FROM SF_Quote_Line_Item__c];
        
        System.debug('@@@@@@@@bundelQli: ' + bundleQli);
        
        List<String> bundleQlisIds = new List<String>();
        
        bundleQlisIds.add(bundleQli[0].Id);
            
        System.debug(SF_QliController.computePrices(bundleQlisIds));
    }
}