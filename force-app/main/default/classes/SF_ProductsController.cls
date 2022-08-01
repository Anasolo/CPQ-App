/**
* ============================================
* @claseName: SF_ProductsController
* @description: This class is Product2 controller
* @author: Jubo M.
* @testClass: SF_ProductsControllerTest
* @dateCreated: 28/05/2022
* @lastChange: 23/06/2022 by Jubo M.
* ============================================ 
*/

public with sharing class SF_ProductsController {
    /**
    * @author: Jubo M.
    * @description: This method returns option products of the product of which Id is passed to this method
    */   
   @AuraEnabled(cacheable=true)
   public static List<Product2> getOptionProducts(Id productId) {
        return [SELECT Id, Name, Product__c FROM Product2 WHERE Product__c = :productId];
   }


   @AuraEnabled(cacheable=true) 
   public static List<ProductData> getOpProducts(Id quoteId) {
     System.debug('@@@@@quoteId: ' + quoteId);
     List<ProductData> productProps = new List<ProductData>();
     Map<Id, List<Id>> bundleOpProdIdsMap = new Map<Id, List<Id>>();
     List<Id> opProdsIds = new List<Id>();
     List<Id> bundleProdIds = new List<Id>();

     List<SF_Quote_Line_Item__c> bundleQlis = [SELECT Id, Product__c FROM SF_Quote_Line_Item__c WHERE SF_Quote__c = :quoteId AND Is_Bundle__c = TRUE AND Product__r.Stand_Alone__c = FALSE];

     if(bundleQlis.size() > 0) {
          for(SF_Quote_Line_Item__c qli : bundleQlis) {
               bundleProdIds.add(qli.Product__c);
          }
     }

     System.debug('@@@@@bundleQlis: ' + bundleQlis);

     List<Product2> opProducts = [SELECT Id, Product__c FROM Product2 WHERE Product__c IN :bundleProdIds];

     // List<SF_Quote_Line_Item__c> optionQlis = [SELECT Id, Product__c, Product__r.Product__c FROM SF_Quote_Line_Item__c WHERE Quote_Line_Item__c IN :bundleQlis];

     if(opProducts.size() > 0) {
          for(Product2 product : opProducts) {
               if(!bundleOpProdIdsMap.containsKey(product.Product__c)) {
                    bundleOpProdIdsMap.put(product.Product__c, new List<Id>());
               }

               bundleOpProdIdsMap.get(product.Product__c).add(product.Id);
               opProdsIds.add(product.Id);
          }
     }

     System.debug('@@@@@opProdsIds: ' + opProdsIds);

     List<SF_Price_List_Item__c> plis = [SELECT Id, Product__c, Product__r.Product__c, Product__r.Name, Base_Price__c, CurrencyIsoCode FROM SF_Price_List_Item__c WHERE Active__c = TRUE AND Product__c IN :opProdsIds];

     System.debug('@@@@@plis: ' + plis);

     for(SF_Price_List_Item__c pli : plis) {
          ProductData prodData = new ProductData();
          prodData.opProductId = pli.Product__c;
          prodData.bundleProdId = pli.Product__r.Product__c;
          prodData.productName = pli.Product__r.Name;
          prodData.productPrice = pli.Base_Price__c;
          prodData.currencyCode = pli.CurrencyIsoCode;
          prodData.priceListItem = pli.Id;

          productProps.add(prodData);
     }

     System.debug('@@@@@productProps: ' + productProps);

     return productProps;
   }

   public class ProductData {
     @AuraEnabled public String opProductId {get; set;}
     @AuraEnabled public String bundleProdId {get; set;}
     @AuraEnabled public String productName  {get; set;}
     @AuraEnabled public Decimal productPrice  {get; set;}
     @AuraEnabled public String currencyCode  {get; set;}
     @AuraEnabled public String priceListItem  {get; set;}
 }
}