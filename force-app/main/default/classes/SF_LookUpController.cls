/**
* ============================================
* @claseName: SF_LookUpController
* @description: This class contains the logic for sf_lookupComponent.lwc
* @author: Jubo M.
* @testClass: SF_LookupControllerTest
* @dateCreated: 28/05/2022
* @lastChange: 23/06/2022 by Jubo M.
* ============================================ 
*/
public with sharing class SF_LookUpController {
     /**
    * @author: Jubo M.
    * @description: This method fetches requested products by end user
    */   
    @AuraEnabled
    public static List<Product2> fetchRecords(Id priceListId) {
        List<Product2> products = new List<Product2>();
        Set<Id> optionProductIds = new Set<Id>();
        Map<Id, Double> productPliPricesMap = new Map<Id, Double>();
        List<Product2> filteredRecs = [SELECT Id, Optional__c, Name, Stand_Alone__c, Is_Bundle__c, (SELECT Id, Name, Optional__c FROM Products__r), (SELECT Id, Base_Price__c, CurrencyIsoCode FROM SF_Price_List_Items__r WHERE SF_Price_List__c = :priceListId AND Active__c = TRUE) FROM Product2 WHERE Is_Bundle__c = TRUE];

         for(Product2 product : filteredRecs) {
            if((product.SF_Price_List_Items__r.size() > 0 && product.Products__r.size() > 0) || product.Stand_Alone__c == true) {
                products.add(product);
            }
         }

        return products;
    }

    /**
    * @author: Jubo M.
    * @description: This is returning map of products and their prices
    */  
    @AuraEnabled(cacheable=true)
    public static Map<Id, SF_Price_List_Item__c> getProductPliPriceMap(List<Id> productIds, Id priceListId) {
        Map<Id, SF_Price_List_Item__c> productPliPriceMap = new Map<Id, SF_Price_List_Item__c>();

        List<SF_Price_List_Item__c> plis = [SELECT Id, Product__c, Base_Price__c FROM SF_Price_List_Item__c WHERE SF_Price_List__c = :priceListId AND Active__c = TRUE AND Product__r.Is_Bundle__c = FALSE AND Product__c IN :productIds];

        for(SF_Price_List_Item__c pli : plis) {
            productPliPriceMap.put(pli.Product__c, pli);
        }

        return productPliPriceMap;
    }
}