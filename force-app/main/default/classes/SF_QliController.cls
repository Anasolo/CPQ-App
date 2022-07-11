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
    //Yoooooooooooo 
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
                qlisMap.get(qli.Quote_Line_Item__c).add(qli);
            }
        }

        for(Id qliId : qlisMap.keySet()) {
            QlisData newQlisData = new QlisData();
            newQlisData.bundleQli = bundleQlisMap.get(qliId);
            newQlisData.optionQlis = qlisMap.get(qliId).size() > 0 ? qlisMap.get(qliId) : new List<SF_Quote_Line_Item__c>();
            qlisDataList.add(newQlisData);
        }

        // List<SF_Quote_Line_Item__c> qlis = Database.query('SELECT Id, CurrencyIsoCode, Product__r.Stand_Alone__c, SF_Price_List_Item__c,' + query + ' ' + 'FROM SF_Quote_Line_Item__c WHERE SF_Quote__c = :quoteId');

        // List<SF_Quote_Line_Item__c> allQlis = [SELECT Id, Product__c, Is_Bundle__c, Product__r.Is_Bundle__c, Product__r.Stand_Alone__c, Product__r.Product__c FROM SF_Quote_Line_Item__c WHERE Id IN :qlis];

        // for(SF_Quote_Line_Item__c qli : qlis) {
        //     qlisMap.put(qli.Id, qli);
        // }

        // for(SF_Quote_Line_Item__c qli : allQlis) {
        //     if(qli.Is_Bundle__c) {
        //         bundleProductsIds.add(qli.Product__c);
        //         productsIdsQlisMap.put(qli.Product__c, qlisMap.get(qli.Id));
        //         finalMap.put(qlisMap.get(qli.Id), new List<SF_Quote_Line_Item__c>());
        //     }
        // }

        // for(SF_Quote_Line_Item__c qli : allQlis) {
        //     if(qli.Is_Bundle__c == false) {
        //        if(bundleProductsIds.contains(qli.Product__r.Product__c)) {
        //          finalMap.get(productsIdsQlisMap.get(qli.Product__r.Product__c)).add(qlisMap.get(qli.Id));
        //        }
        //     }
        // }

        // List<QlisData> qlisDataList = new List<QlisData>();

        // for(SF_Quote_Line_Item__c qli : finalMap.keySet()) {
        //     QlisData newQlisData = new QlisData();
        //     newQlisData.bundleQli = qli;
        //     newQlisData.optionQlis = finalMap.get(qli);
        //     qlisDataList.add(newQlisData);
        // }
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
        List<String> standAloneQliIds = new List<String>();

         for(String productId : productIdQliInfoMap.keySet()) {
            if(productIdQliInfoMap.get(productId).get('hasOptionalProducts') == 'true') {
                bundleProdIds.add(productId);
                bundleQlisToInsert.add(new SF_Quote_Line_Item__c(Name = productId, SF_Quote__c = quoteId, Product__c = productId, Quantity__c = Integer.valueOf(productIdQliInfoMap.get(productId).get('quantity')), SF_Price_List_Item__c = productIdQliInfoMap.get(productId).get('priceListItem')));
            } else if(productIdQliInfoMap.get(productId).get('hasOptionalProducts') == 'false') {
                opProdIds.add(productId);
            } else {
                standAloneQlisToInsert.add(new SF_Quote_Line_Item__c(Name = productId, SF_Quote__c = quoteId, Product__c = productId, Quantity__c = Integer.valueOf(productIdQliInfoMap.get(productId).get('quantity')), SF_Price_List_Item__c = productIdQliInfoMap.get(productId).get('priceListItem')));
            }
        }
        System.debug('@@@@@@bundelQlisTOInssert: ' + bundleQlisToInsert);
        try {
            Database.SaveResult[] srBundleQlisList = Database.insert(bundleQlisToInsert);

            for (Database.SaveResult sr : srBundleQlisList) {
                bundleQlisIds.add(sr.getId());
            }

            Database.SaveResult[] srStandAloneQlisList = Database.insert(standAloneQlisToInsert);

            for (Database.SaveResult sr : srStandAloneQlisList) {
                standAloneQliIds.add(sr.getId());
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

        Map<Id, Double> opQlisPricesMap = computePrices(bundleQlisIds, standAloneQliIds);
        
        List<SF_Quote_Line_Item__c> opQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        List<SF_Quote_Line_Item__c> saQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        for(SF_Quote_Line_Item__c qli : opQlisToInsert) {
            opQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qli.Id, Total_Price__c = opQlisPricesMap.get(qli.Id)));
        }

        for(SF_Quote_Line_Item__c qli : standAloneQlisToInsert) {
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

        for(Map<String, String> qliObj : qlis) {
            if(qliObj.get('standAlone') == 'true') {
                saQlisIds.add(qliObj.get('id'));
            } else {
                opQlisIds.add(qliObj.get('id'));
            }
            qlisToUpdate.add(new SF_Quote_Line_Item__c(Id=qliObj.get('id'), Quantity__c=Integer.valueOf(qliObj.get('newValue'))));
        }

        try {
            update qlisToUpdate;
        } catch(DmlException ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        List<SF_Quote_Line_Item__c> bundleQlis = [SELECT Id, Quote_Line_Item__c FROM SF_Quote_Line_Item__c WHERE Id IN :opQlisIds];

        List<String> bundleQlisIds = new List<String>();

        for(SF_Quote_Line_Item__c qli : bundleQlis) {
            bundleQlisIds.add(qli.Quote_Line_Item__c);
        }

        Map<Id, Double> opQlisPricesMap = computePrices(bundleQlisIds, saQlisIds);

        List<SF_Quote_Line_Item__c> opQlisToUpdate = new List<SF_Quote_Line_Item__c>();
        List<SF_Quote_Line_Item__c> saQlisToUpdate = new List<SF_Quote_Line_Item__c>();

        for(String qliId : opQlisIds) {
            opQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qliId, Total_Price__c = opQlisPricesMap.get(qliId)));
        }

        for(String qliId : saQlisIds) {
            saQlisToUpdate.add(new SF_Quote_Line_Item__c(Id = qliId, Total_Price__c = opQlisPricesMap.get(qliId)));
        }

        try {
            update opQlisToUpdate;
            update saQlisToUpdate;
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
            List<SF_Quote_Line_Item__c> budnleQliListToInsert = new List<SF_Quote_Line_Item__c>();
            List<SF_Quote_Line_Item__c> qlisToInsert = new List<SF_Quote_Line_Item__c>();
       
            Id bundleQliId;

            SF_Quote_Line_Item__c bundleQli = new SF_Quote_Line_Item__c(Name = bundleQliMap.get('Name'), Unit_Price__c = Double.valueOf(bundleQliMap.get('Unit_Price__c')), List_Price__c = Double.valueOf(bundleQliMap.get('List_Price__c')), Total_Price__c = Double.valueOf(bundleQliMap.get('Total_Price__c')),Is_Bundle__c = true, Product__c=bundleQliMap.get('Product__c'), SF_Price_List_Item__c = bundleQliMap.get('SF_Price_List_Item__c'), Quantity__c = Integer.valueOf(bundleQliMap.get('Quantity__c')), SF_Quote__c = bundleQliMap.get('SF_Quote__c'));

            budnleQliListToInsert.add(bundleQli);

            try {
                Database.SaveResult[] srList = Database.insert(budnleQliListToInsert, false);
                for (Database.SaveResult sr : srList) {
                    bundleQliId = sr.getId();
                }
                successMessage = Label.cloneQliSuccessMessageLabel;
            } catch(DmlException ex) {
                System.debug('@@@@@Error occured during inserting bundleQli: ' + ex.getMessage());
            }


            if(opQliMap != null && !opQliMap.isEmpty()) {
                for(Map<String, String> opQli : opQliMap) {
                    qlisToInsert.add(new SF_Quote_Line_Item__c(Name = opQli.get('Name'), Quote_Line_Item__c = bundleQliId, Unit_Price__c = Double.valueOf(opQli.get('Unit_Price__c')), List_Price__c = Double.valueOf(opQli.get('List_Price__c')), Total_Price__c = Double.valueOf(opQli.get('Total_Price__c')),Is_Bundle__c = false, Product__c=opQli.get('Product__c'), SF_Price_List_Item__c = opQli.get('SF_Price_List_Item__c'), Quantity__c = Integer.valueOf(opQli.get('Quantity__c')), SF_Quote__c = opQli.get('SF_Quote__c')));
                }
    
                try {
                    insert qlisToInsert;
                } catch(DmlException ex) {
                    System.debug('@@@@@Error during inserting option qlis: ' + ex.getMessage());
                    successMessage = null;
                }
            }
       }

       return successMessage;
    }

    public static Map<Id, Double> computePrices(List<String> bundleQlisIds, List<String> standAloneQlisIds) {
       Map<Id, Id> productQliMap = new Map<Id, Id>();
       Map<Id, Id> qliPliMap = new Map<Id, Id>();
       List<String> productIds = new List<String>();
       List<String> standAloneProductIds = new List<String>();
       Map<Id, Id> productStandAloneQliMap = new Map<Id, Id>();
       Map<Id, Id> saQliPliMap = new Map<Id, Id>();

       List<SF_Quote_Line_Item__c> opQlis = [SELECT Id, Product__c, Quantity__c FROM SF_Quote_Line_Item__c WHERE Quote_Line_Item__c IN :bundleQlisIds];

       List<SF_Quote_Line_Item__c> standAloneQlis = [SELECT Id, Product__c, Quantity__c FROM SF_Quote_Line_Item__c WHERE Id IN :standAloneQlisIds];


       for(SF_Quote_Line_Item__c qli : opQlis) {
        productQliMap.put(qli.Product__c, qli.Id);
        productIds.add(qli.Product__c);
       }

       for(SF_Quote_Line_Item__c qli : standAloneQlis) {
        productStandAloneQliMap.put(qli.Product__c, qli.Id);
        standAloneProductIds.add(qli.Product__c);
       }


       List<SF_Price_List_Item__c> plis = [SELECT Id, Product__c FROM SF_Price_List_Item__c WHERE Product__c IN :productIds AND Active__c = TRUE];

       List<SF_Price_List_Item__c> standAlonePlis = [SELECT Id, Product__c FROM SF_Price_List_Item__c WHERE Product__c IN :standAloneProductIds AND Active__c = TRUE];

       for(SF_Price_List_Item__c pli : plis) {
            qliPliMap.put(productQliMap.get(pli.Product__c), pli.Id);
       }

       for(SF_Price_List_Item__c pli : standAlonePlis) {
        saQliPliMap.put(productStandAloneQliMap.get(pli.Product__c), pli.Id);
       }


       List<SF_Quantity_Range__c> qRanges = [SELECT Id, Quantity_From__c, Quantity_To__c, Price__c, Price_List_Item__c FROM SF_Quantity_Range__c WHERE Price_List_Item__c IN :plis];

       List<SF_Quantity_Range__c> saQRanges = [SELECT Id, Quantity_From__c, Quantity_To__c, Price__c, Price_List_Item__c FROM SF_Quantity_Range__c WHERE Price_List_Item__c IN :standAlonePlis];

       Map<Id, List<SF_Quantity_Range__c>> pliQrangesMap = new Map<Id, List<SF_Quantity_Range__c>>();
       Map<Id, List<SF_Quantity_Range__c>> saPliQrangesMap = new Map<Id, List<SF_Quantity_Range__c>>();

       for(SF_Quantity_Range__c qr : qRanges) {
            if(!pliQrangesMap.containsKey(qr.Price_List_Item__c)) {
                pliQrangesMap.put(qr.Price_List_Item__c, new List<SF_Quantity_Range__c>());
            } 

            pliQrangesMap.get(qr.Price_List_Item__c).add(qr);
       }

       for(SF_Quantity_Range__c qr : saQRanges) {
        if(!saPliQrangesMap.containsKey(qr.Price_List_Item__c)) {
            saPliQrangesMap.put(qr.Price_List_Item__c, new List<SF_Quantity_Range__c>());
        } 

        saPliQrangesMap.get(qr.Price_List_Item__c).add(qr);
    }

       Map<Id, List<SF_Quantity_Range__c>> qliQrangesMap = new Map<Id, List<SF_Quantity_Range__c>>();

       for(Id qliId : qliPliMap.keySet()) {
        qliQrangesMap.put(qliId, pliQrangesMap.get(qliPliMap.get(qliId)));
       }

       Map<Id, Double> qliPriceMap = new Map<Id, Double>();

       for(SF_Quote_Line_Item__c qli : opQlis) {
         for(SF_Quantity_Range__c qr : qliQrangesMap.get(qli.Id)) {
            if(qli.Quantity__c >= qr.Quantity_From__c && qli.Quantity__c <= qr.Quantity_To__c) {
                qliPriceMap.put(qli.Id, qr.Price__c * qli.Quantity__c);
            }
         }
       }

       for(SF_Quote_Line_Item__c qli : standAloneQlis) {
         for(SF_Quantity_Range__c qr : saPliQrangesMap.get(saQliPliMap.get(qli.Id))) {
            if(qli.Quantity__c >= qr.Quantity_From__c && qli.Quantity__c <= qr.Quantity_To__c) {
                qliPriceMap.put(qli.Id, qr.Price__c * qli.Quantity__c);
            }
         }
       }

       return qliPriceMap;
    }

    public class QlisData {
        @AuraEnabled public SF_Quote_Line_Item__c bundleQli {get; set;}
        @AuraEnabled public List<SF_Quote_Line_Item__c> optionQlis  {get; set;}
    }
}