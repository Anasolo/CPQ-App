/**
* ============================================
* @claseName: SF_QliController
* @description: This class is SF_Quote_Line_Item__c controller
* @author: Jubo M.
* @testClass: SF_QliControllerTest
* @dateCreated: 28/05/2022
* @lastChange: 23/06/2022 by Jubo M.
* ============================================ 
*/

public with sharing class SF_QliController {
    /**
    * @author: Jubo M.
    * @description: This method Quote Line items of the Quote of which Id is passed to the method and dynamically choosing the fields according to the second parameter
    */   
    @AuraEnabled
    public static List<QlisData> getQlis(Id quoteId, List<String> fieldsToQUery) {
        Map<Id, SF_Quote_Line_Item__c> bundleQlisMap = new Map<Id, SF_Quote_Line_Item__c>();
        Map<Id, List<SF_Quote_Line_Item__c>> qlisMap = new Map<Id, List<SF_Quote_Line_Item__c>>();
        List<QlisData> qlisDataList = new List<QlisData>();

        String query = '';
        for(String fieldName : fieldsToQUery) {
            query = query + ' ' +  fieldName + ',';
        }

        query = query.removeEnd(',');

        List<SF_Quote_Line_Item__c> qlis = Database.query('SELECT Id, CurrencyIsoCode, Product__r.Stand_Alone__c, SF_Price_List_Item__c, Is_Bundle__c, Quote_Line_Item__c,' + query + ' ' + 'FROM SF_Quote_Line_Item__c WHERE SF_Quote__c = :quoteId');

        for(SF_Quote_Line_Item__c qli : qlis) {
            if(qli.Is_Bundle__c) {
                bundleQlisMap.put(qli.Id, qli);
                qlisMap.put(qli.Id, new List<SF_Quote_Line_Item__c>());
            }
        }

        for(SF_Quote_Line_Item__c qli : qlis) {
            if(!qli.Is_Bundle__c) {
                if(qlisMap.containsKey(qli.Quote_Line_Item__c)) {
                    qlisMap.get(qli.Quote_Line_Item__c).add(qli);
                }
            }
        }

        for(Id qliId : qlisMap.keySet()) {
            QlisData newQlisData = new QlisData();
            newQlisData.bundleQli = bundleQlisMap.get(qliId);
            newQlisData.optionQlis = qlisMap.get(qliId).size() > 0 ? qlisMap.get(qliId) : new List<SF_Quote_Line_Item__c>();
            qlisDataList.add(newQlisData);
        }

        System.debug('@@@@Qlis: ' + qlisDataList);
        return qlisDataList;
    }

     /**
    * @author: Jubo M.
    * @description: This method returns map of field api name, as a key and map of stirngs, containing field label and data type, as a value
    */   
    @AuraEnabled(cacheable=true) 
    public static Map<String, Map<String, String>> getFieldsLabelsMap() {
        Map<String, Map<String, String>> fieldLabelsApiNamesMap = new Map<String, Map<String, String>>();
        List<String> fieldApiNames = SF_Utils.getFieldApiNames('Fields For Configure Products LWC');

        fieldLabelsApiNamesMap = SF_PlatformCacheData.getCachedConfigProductsFieldsInfo('SF_Quote_Line_Item__c', fieldApiNames);

        return fieldLabelsApiNamesMap;
    } 

     /**
    * @author: Jubo M.
    * @description: This method returns editable fields, according to cusotm metadatatypes data
    */   
    @AuraEnabled(cacheable=true) 
    public static List<String> getEditableFields() {
        List<FieldsConfig__mdt> fieldsConfig = [SELECT Id, Fields__c FROM FieldsConfig__mdt WHERE Label = 'Editable Fields' LIMIT 1];

        List<String> fieldApiNames = fieldsConfig[0].Fields__c.split(',');

        return fieldApiNames;
    } 

     /**
    * @author: Jubo M.
    * @description: This method inserts Quote Line Items
    */   
    @AuraEnabled
    public static String insertQlis(Map<String, Map<String, String>> productIdQliInfoMap, Id quoteId) {
        String successMessage = Label.quoteLineItemsCreationSuccessLabel;
        System.debug('@@@@@@bundelQlisTOInssert: ' + productIdQliInfoMap);

        List<SF_Quote_Line_Item__c> bundleQlisToInsert = new List<SF_Quote_Line_Item__c>();
        List<SF_Quote_Line_Item__c> standAloneQlisToInsert = new List<SF_Quote_Line_Item__c>();
        Map<String, String> prodIdQliIdMap = new Map<String, String>();
        List<String> bundleProdIds = new List<String>();
        List<String> opProdIds = new List<String>();
        List<String> bundleQlisIds = new List<String>();

         for(String productId : productIdQliInfoMap.keySet()) {
            if(productIdQliInfoMap.get(productId).get('hasOptionalProducts') == 'true' || productIdQliInfoMap.get(productId).get('hasOptionalProducts') == 'standAlone') {
                bundleProdIds.add(productId);
                bundleQlisToInsert.add(new SF_Quote_Line_Item__c(Name = productId, SF_Quote__c = quoteId, Product__c = productId, Quantity__c = Integer.valueOf(productIdQliInfoMap.get(productId).get('quantity')), SF_Price_List_Item__c = productIdQliInfoMap.get(productId).get('priceListItem')));
            } else {
                opProdIds.add(productId);
            }
        }
        System.debug('@@@@@@bundelQlisTOInssert: ' + bundleQlisToInsert);
        try {
            Database.SaveResult[] srBundleQlisList = Database.insert(bundleQlisToInsert);

            for (Database.SaveResult sr : srBundleQlisList) {
                bundleQlisIds.add(sr.getId());
            }

        } catch(DmlException ex) {
            System.debug(ex.getMessage());
        }

        List<SF_Quote_Line_Item__c> bundleQlis = [SELECT Id, Product__c FROM SF_Quote_Line_Item__c WHERE Product__c IN :bundleProdIds];

        if(bundleQlis.size() > 0) {
            for(SF_Quote_Line_Item__c qli : bundleQlis) {
                prodIdQliIdMap.put(qli.Product__c, qli.Id);
            }
        }

        List<Product2> opProducts = [SELECT Id, Product__c FROM Product2 WHERE Product__c IN :bundleProdIds AND Id IN :opProdIds];

        List<SF_Quote_Line_Item__c> opQlisToInsert = new List<SF_Quote_Line_Item__c>();


        for(Product2 p : opProducts) {
            opQlisToInsert.add(new SF_Quote_Line_Item__c(Name = p.Id, SF_Quote__c = quoteId, Product__c = p.Id, Quantity__c = Integer.valueOf(productIdQliInfoMap.get(p.Id).get('quantity')), SF_Price_List_Item__c = productIdQliInfoMap.get(p.Id).get('priceListItem'), Quote_Line_Item__c = prodIdQliIdMap.get(p.Product__c)));
        }

        System.debug('@@@@opQlisToInsert: ' + opQlisToInsert);

        try {
            insert opQlisToInsert;
        } catch(DmlException ex) {
            System.debug(ex.getMessage());
        }

        Map<Id, Double> opQlisPricesMap = computePrices(bundleQlisIds);

        System.debug('@@@@@opQlisPricesMap: ' + opQlisPricesMap);
        
        List<SF_Quote_Line_Item__c> opQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        List<SF_Quote_Line_Item__c> saQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        for(SF_Quote_Line_Item__c qli : opQlisToInsert) {
            opQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qli.Id, Total_Price__c = opQlisPricesMap.get(qli.Id)));
        }

        for(SF_Quote_Line_Item__c qli : bundleQlisToInsert) {
            saQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qli.Id, Total_Price__c = opQlisPricesMap.get(qli.Id)));
        }

        try {
            update opQlisToUpdate;
            update saQlisToUpdate;
        } catch(DmlException ex) {
            System.debug(ex.getMessage());
        }

        return successMessage;
    }

     /**
    * @author: Jubo M.
    * @description: This method updates Quote Line Items
    */   
    @AuraEnabled
    public static String updateQlis(List<Map<String, String>> qlis) {
        String successMessage;
        List<SF_Quote_Line_Item__c> qlisToUpdate = new List<SF_Quote_Line_Item__c>();

        List<String> opQlisIds = new List<String>();
        List<String> saQlisIds = new List<String>();

        List<String> qlisIds = new List<String>();

        for(Map<String, String> qliObj : qlis) {
            qlisIds.add(qliObj.get('id'));

            qlisToUpdate.add(new SF_Quote_Line_Item__c(Id=qliObj.get('id'), Quantity__c=Integer.valueOf(qliObj.get('newValue'))));
        }

        try {
            update qlisToUpdate;
        } catch(DmlException ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        List<SF_Quote_Line_Item__c> allQlis = [SELECT Id, Quote_Line_Item__c FROM SF_Quote_Line_Item__c WHERE Id IN :qlisIds];

        List<String> bundleQlisIds = new List<String>();

        for(SF_Quote_Line_Item__c qli : allQlis) {
            if(String.isBlank(qli.Quote_Line_Item__c)) {
                bundleQlisIds.add(qli.Id);
            } else {
                bundleQlisIds.add(qli.Quote_Line_Item__c);
            }
        }

        Map<Id, Double> qlisPricesMap = computePrices(bundleQlisIds);

        List<SF_Quote_Line_Item__c> allQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        for(String qliId : qlisIds) {
            allQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qliId, Total_Price__c = qlisPricesMap.get(qliId)));
        }

        try {
            update allQlisToUpdate;
            successMessage = Label.quoteLineItemsUpdateSuccessLabel;
        } catch(DmlException ex) {
            System.debug(ex.getMessage());
        }

        return successMessage;
    }

     /**
    * @author: Jubo M.
    * @description: This method updates Quote Line Items
    */   
    @AuraEnabled
    public static String cloneQli(Map<String, String> bundleQliMap, List<Map<String, String>> opQliMap) {
       String successMessage;
       if(bundleQliMap != null && !bundleQliMap.isEmpty()) {
            String query = '';

            List<Schema.SObjectField> qliFields = Schema.getGlobalDescribe().get('SF_Quote_Line_Item__c').getDescribe().fields.getMap().values();

            System.debug('@@@@@@qliFields'+ qliFields);

            for (Schema.SObjectField sObjectField : qliFields) {
                query += sObjectField.getDescribe().getName() + ',';
            }

            query = query.removeEnd(',');

            Id bundleQliId = bundleQliMap.get('Id');

            Id clonedBundleQliId;

            List<String> opQlisIds = new List<String>();

            for(Map<String, String> opQli : opQliMap) {
               opQlisIds.add(opQli.get('Id'));
            }

            List<SF_Quote_Line_Item__c> qlisToClone = Database.query('SELECT ' + query + ' FROM SF_Quote_Line_Item__c WHERE Id = :bundleQliId OR Id IN :opQlisIds');

            List<SF_Quote_Line_Item__c> bundleQliToClone = new List<SF_Quote_Line_Item__c>();

            List<SF_Quote_Line_Item__c> opQlisToClone = new List<SF_Quote_Line_Item__c>();

            for(SF_Quote_Line_Item__c qli : qlisToClone) {
                if(qli.Id == bundleQliId) {
                    bundleQliToClone.add(qli);
                } else {
                    qli.Id = null;
                    opQlisToClone.add(qli);
                }
            }


            SF_Quote_Line_Item__c clonedBundleQli = bundleQliToClone[0].clone(false, true, false, false);

            List<SF_Quote_Line_Item__c> clonedBundleQliList = new List<SF_Quote_Line_Item__c>{clonedBundleQli};

            try {
                Database.SaveResult[] srList = Database.insert(clonedBundleQliList, false);
                for (Database.SaveResult sr : srList) {
                    clonedBundleQliId = sr.getId();
                }

                successMessage = Label.cloneQliSuccessMessageLabel;
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }

            List<SF_Quote_Line_Item__c> clonedOpQlis = opQlisToClone.clone();

            for(SF_Quote_Line_Item__c qli : clonedOpQlis) {
                qli.Quote_Line_Item__c = clonedBundleQliId;
            }

            try {
                insert clonedOpQlis;
            } catch(DmlException ex) {
                successMessage = null;
                throw new AuraHandledException(ex.getMessage());
            }
       }

       return successMessage;
    }

    public static Map<Id, Double> computePrices(List<String> bundleQlisIds) {
       Map<Id, Id> productQliMap = new Map<Id, Id>();
       Map<Id, Id> qliPliMap = new Map<Id, Id>();
       List<String> productIds = new List<String>();

       List<SF_Quote_Line_Item__c> qlis = [SELECT Id, Product__c, Quantity__c FROM SF_Quote_Line_Item__c WHERE Quote_Line_Item__c IN :bundleQlisIds OR Id IN :bundleQlisIds];



       for(SF_Quote_Line_Item__c qli : qlis) {
        productQliMap.put(qli.Product__c, qli.Id);
        productIds.add(qli.Product__c);
       }


       List<SF_Price_List_Item__c> plis = [SELECT Id, Product__c FROM SF_Price_List_Item__c WHERE Product__c IN :productIds AND Active__c = TRUE];

       for(SF_Price_List_Item__c pli : plis) {
            qliPliMap.put(productQliMap.get(pli.Product__c), pli.Id);
       }


       List<SF_Quantity_Range__c> qRanges = [SELECT Id, Quantity_From__c, Quantity_To__c, Price__c, Price_List_Item__c FROM SF_Quantity_Range__c WHERE Price_List_Item__c IN :plis];

       Map<Id, List<SF_Quantity_Range__c>> pliQrangesMap = new Map<Id, List<SF_Quantity_Range__c>>();

       for(SF_Quantity_Range__c qr : qRanges) {
            if(!pliQrangesMap.containsKey(qr.Price_List_Item__c)) {
                pliQrangesMap.put(qr.Price_List_Item__c, new List<SF_Quantity_Range__c>());
            } 

            pliQrangesMap.get(qr.Price_List_Item__c).add(qr);
       }

       Map<Id, List<SF_Quantity_Range__c>> qliQrangesMap = new Map<Id, List<SF_Quantity_Range__c>>();

       for(Id qliId : qliPliMap.keySet()) {
        qliQrangesMap.put(qliId, pliQrangesMap.get(qliPliMap.get(qliId)));
       }

       Map<Id, Double> qliPriceMap = new Map<Id, Double>();

       for(SF_Quote_Line_Item__c qli : qlis) {
         for(SF_Quantity_Range__c qr : qliQrangesMap.get(qli.Id)) {
            if(qli.Quantity__c >= qr.Quantity_From__c && qli.Quantity__c <= qr.Quantity_To__c) {
                qliPriceMap.put(qli.Id, qr.Price__c * qli.Quantity__c);
            }
         }
       }

       System.debug('@@@@@qliPriceMap: ' + qliPriceMap);

       return qliPriceMap;
    }

    public static Id getPli(Id productId) {
        List<SF_Price_List_Item__c> plis = [SELECT Id FROM SF_Price_List_Item__c WHERE Active__c = TRUE AND Product__c = :productId];

        return plis[0].Id;
    }

    @AuraEnabled
    public static String deleteQlis(List<Id> qlisIds) {
        String successMessage;

        SF_ProductRulesService.deleteQlis(qlisIds);

        try {
            Database.delete(qlisIds, false);
            successMessage = Label.qlisDeletedSuccessfullyLabel;
        } catch(DmlException ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        return successMessage;
    }

    @AuraEnabled
    public static String insertOpQlis(List<ProductsToQlisData> prodsToQlisData, Id quoteId) {
        System.debug('@@@@@heyy ' + prodsToQlisData);
        String successMessage;

        List<SF_Quote_Line_Item__c> qlisToInsert = new List<SF_Quote_Line_Item__c>();
        List<String> bundleQlisIds = new List<String>();
        List<SF_Quote_Line_Item__c> qlisToUpdate = new List<SF_Quote_Line_Item__c>();
        List<SF_Quote_Line_Item__c> allQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        if(prodsToQlisData != null && prodsToQlisData.size() > 0) {
            for(ProductsToQlisData ptq : prodsToQlisData) {
                if(ptq.action == 'insert') {
                    qlisToInsert.add(new SF_Quote_Line_Item__c(SF_Quote__c = quoteId, Product__c = ptq.productId, SF_Price_List_Item__c = ptq.priceListItemId, Quantity__c = ptq.quantity, Quote_Line_Item__c = ptq.quoteLineItemId));
                } else {
                    qlisToUpdate.add(new SF_Quote_Line_Item__c(Id = ptq.recordId, SF_Quote__c = quoteId, Quantity__c = ptq.quantity));
                }
            }
    
            try {
                insert qlisToInsert;
                update qlisToUpdate;
                successMessage = Label.bundleConfiguredSuccessLabel;
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }

            if(qlisToInsert.size() > 0) {
                bundleQlisIds.add(qlisToInsert[0].Quote_Line_Item__c);
                
                Map<Id, Double> opQliPriceMap = computePrices(bundleQlisIds);

                if(opQliPriceMap != null && opQliPriceMap.size() > 0) {
                    for(Id qliId : opQliPriceMap.keySet()) {
                        allQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qliId, Total_Price__c = opQliPriceMap.get(qliId)));
                    }
    
                    try {
                        update allQlisToUpdate;
                    } catch(DmlException ex) {
                        throw new AuraHandledException(ex.getMessage());
                    }
                }
            }
        }


        return successMessage;
    }


    public class QlisData {
        @AuraEnabled public SF_Quote_Line_Item__c bundleQli {get; set;}
        @AuraEnabled public List<SF_Quote_Line_Item__c> optionQlis  {get; set;}
    }

    public class ProductsToQlisData {
        @AuraEnabled public Id recordId {get; set;}
        @AuraEnabled public Id productId {get; set;}
        @AuraEnabled public String priceListItemId {get; set;}
        @AuraEnabled public Integer quantity {get; set;}
        @AuraEnabled public Id quoteLineItemId {get; set;}
        @AuraEnabled public String action {get; set;}
    }
}