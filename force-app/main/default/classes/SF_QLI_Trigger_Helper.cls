/**
* ============================================
* @claseName: SF_QLI_Trigger_Helper.cls
* @description: This class is called from trigger: SF_QLITrigger when Trigger is before insert 
* @author: Jubo M.
* @dateCreated: 20/05/2022
* @lastChange: 23/05/2022 by Jubo M.
* ============================================ 
*/ 
public class SF_QLI_Trigger_Helper {
    /**
    * Assigning field values to SF Quote Line Items according to respective parent Product2 and SF_Price_List_Item__c fields values
    * @since 20/05/2022
    * @author Jubo M.
    */
    public static void setQliValues(List<SF_Quote_Line_Item__c> qlisNew) {
        List<SF_Quote_Line_Item__c> qlis = new List<SF_Quote_Line_Item__c>();
        
        for(SF_Quote_Line_Item__c qli : qlisNew) {
                qlis.add(qli);
        }
            
        Set<Id> productIds = new Set<Id>();
        Set<Id> pliIds = new Set<Id>();
            
        Map<Id, List<SF_Quote_Line_Item__c>> productsQLisMap = new Map<Id, List<SF_Quote_Line_Item__c>>();
        Map<Id, List<SF_Quote_Line_Item__c>> plisQLisMap = new Map<Id, List<SF_Quote_Line_Item__c>>();
            
        for(SF_Quote_Line_Item__c qli : qlis) {
             productIds.add(qli.Product__c);
             pliIds.add(qli.SF_Price_List_Item__c);
        }
            
        List<Product2> products = [SELECT Id, Name, Description__c, Is_Bundle__c FROM Product2 WHERE Id IN :productIds];
        List<SF_Price_List_Item__c> plis = [SELECT Id, Base_Price__c FROM SF_Price_List_Item__c WHERE Id IN :pliIds];
            
        for(SF_Quote_Line_Item__c qli : qlis) {
            if(!productsQLisMap.containsKey(qli.Product__c)) {
                productsQLisMap.put(qli.Product__c, new List<SF_Quote_Line_Item__c>());
            }
                
            productsQLisMap.get(qli.Product__c).add(qli);
                
                if(!plisQLisMap.containsKey(qli.SF_Price_List_Item__c)) {
                    plisQLisMap.put(qli.SF_Price_List_Item__c, new List<SF_Quote_Line_Item__c>());
                }
                
             plisQLisMap.get(qli.SF_Price_List_Item__c).add(qli);
          }
            
        for(SF_Quote_Line_Item__c qli : qlis) {
              for(Product2 product : products) {
                  if(product.Id == qli.Product__c) {
                      qli.List_Item_Description__c = product.Description__c;
					  qli.Is_Bundle__c = product.Is_Bundle__c;
			   		  qli.Name = product.Name;
                  }
              }
                 
               for(SF_Price_List_Item__c pli : plis) {
                   if(pli.Id == qli.SF_Price_List_Item__c) {
                      qli.List_Price__c = pli.Base_Price__c;
					  qli.Unit_Price__c = pli.Base_Price__c;
                   }
               }
        }
    }
}