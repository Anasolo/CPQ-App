/**
* ============================================
* @claseName: SF_ProductsControllerTest
* @description: This class tests SF_LookUpController
* @author: Jubo M.
* @Class: SF_ProductsController
* @dateCreated: 24/06/2022
* @lastChange: 24/06/2022 by Jubo M.
* ============================================ 
*/
@isTest
public with sharing class SF_ProductsControllerTest {
        @testSetup
        public static void makeData() {
            Product2 product = new Product2(Name='Test Product', Is_Bundle__c = true);
            insert product;
    
            Product2 optionProduct = new Product2(Name='Test Option Product', Is_Bundle__c = false, Product__c = product.Id);
    
            insert optionProduct;
    
            SF_Price_List__c pl = new SF_Price_List__c(Name='USD Price List', Active__c=true, CurrencyIsoCode='USD');
            
            insert pl;
    
            SF_Price_List_Item__c pli = new SF_Price_List_Item__c(Active__c = true, Base_Price__c = 2000, SF_Price_List__c = pl.Id, Product__c = product.Id, CurrencyIsoCode = 'USD');
    
            insert pli;
    
            SF_Price_List_Item__c pli2 = new SF_Price_List_Item__c(Active__c = true, Base_Price__c = 200, SF_Price_List__c = pl.Id, Product__c = optionProduct.Id, CurrencyIsoCode = 'USD');
    
            insert pli2;
    
        }
    /**
    * @author: Jubo M.
    * @description: This method tests SF_ProductsController.getOptionProducts method
    */   
    @isTest
    public static void testGetOptionProducts() {
       List<Product2> products = [SELECT Id, (SELECT Id FROM Products__r) FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

       List<Product2> optionProducts = SF_ProductsController.getOptionProducts(products[0].Id);

       System.assertEquals(products[0].Products__r[0].Id, optionProducts[0].Id, 'PIncorrect option products were retreived');
    }
}