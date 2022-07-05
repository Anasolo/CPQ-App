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
}