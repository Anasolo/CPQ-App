/**
* ============================================
* @claseName: SF_LookupControllerTest
* @description: This class tests SF_LookUpController
* @author: Jubo M.
* @Class: SF_LookUpController
* @dateCreated: 24/06/2022
* @lastChange: 24/06/2022 by Jubo M.
* ============================================ 
*/
@isTest
public with sharing class SF_LookupControllerTest {
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
    * @description: This method tests SF_LookupControllerTest.fetchRecords method
    */   
    @isTest
    public static void testFetchRecords() {
        List<SF_Price_List__c> pl = [SELECT Id FROM SF_Price_List__c LIMIT 1];
        List<Product2> products = SF_LookUpController.fetchRecords(pl[0].Id);

        System.assert(products.size() > 0, 'Products were not retreived');
    }

    /**
    * @author: Jubo M.
    * @description: This method tests SF_LookupControllerTest.getProductPliPriceMap method
    */   
    @isTest
    public static void testGetProductPliPriceMap() {
      List<SF_Price_List__c> pl = [SELECT Id FROM SF_Price_List__c WHERE Name='USD Price List' LIMIT 1];
      List<Product2> product = [SELECT Id FROM Product2 WHERE Name ='Test Option Product' LIMIT 1];
      List<SF_Price_List_Item__c> pli = [SELECT Id FROM SF_Price_List_Item__c WHERE Product__c = :product[0].Id];

      List<Id> productIds = new List<Id>();
      productIds.add(product[0].Id);

      Map<Id, SF_Price_List_Item__c> productsPlisMap = SF_LookUpController.getProductPliPriceMap(productIds, pl[0].Id);

      System.assert(productsPlisMap.get(product[0].Id).Id == pli[0].Id, 'Correct map was not returned');
    }
}