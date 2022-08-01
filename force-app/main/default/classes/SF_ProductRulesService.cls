public with sharing class SF_ProductRulesService {

    static Map<String, List<Map<String, String>>> repriceRes = new Map<String, List<Map<String, String>>>();

    @AuraEnabled
    public static List<RepriceData> reprice(Id quoteId) {
        List<SF_Quote_Line_Item__c> qlisToInsert = new List<SF_Quote_Line_Item__c>();
        List<Id> qlisToDelete = new List<Id>();
        List<String> bundleQlis = new List<String>();
        Map<Id, List<SF_Quote_Line_Item__c>> bundleQliOptionQlisMap = new Map<Id, List<SF_Quote_Line_Item__c>>();
        List<SF_Quote_Line_Item__c> allOptionQlis = new List<SF_Quote_Line_Item__c>();
        List<SF_Quote_Line_Item__c> bundleQlisToInsert = new List<SF_Quote_Line_Item__c>();
        List<Id> bundleProductIds = new List<String>();
        List<Id> bundleQlisToInsertIds = new List<Id>();

        if(quoteId != null) {
            List<String> productIds = new List<String>();

            Map<Id, SF_Quote_Line_Item__c> productQliMap = new Map<Id, SF_Quote_Line_Item__c>();
            

            List<SF_Quote_Line_Item__c> qlis = [SELECT Id, Product__c, Product__r.Is_Bundle__c, Is_Bundle__c,Product__r.Stand_Alone__c, Quantity__c, Quote_Line_Item__c, Product__r.Optional__c FROM SF_Quote_Line_Item__c WHERE SF_Quote__c = :quoteId];

            if(qlis.size() > 0) {
                for(SF_Quote_Line_Item__c qli : qlis) {
                    if(!qli.Is_Bundle__c) {
                        if(!bundleQliOptionQlisMap.containsKey(qli.Quote_Line_Item__c)) {
                            bundleQliOptionQlisMap.put(qli.Quote_Line_Item__c, new List<SF_Quote_Line_Item__c>());
                        }

                        bundleQliOptionQlisMap.get(qli.Quote_Line_Item__c).add(qli);
                    }
                    productIds.add(qli.Product__c);
                    productQliMap.put(qli.Product__c, qli);
                }

    
                List<Product2> products = [SELECT Id, Stand_Alone__c, Is_Bundle__c, (SELECT Id, Product__c, Product__r.Product__c, Product__r.Name, Product__r.Is_Bundle__c, Product__r.Stand_Alone__c, Product__r.Product__r.Name, Active__c FROM Product_Rules__r WHERE Active__c = TRUE) FROM Product2 WHERE Id IN :productIds];
    
                List<SF_Product_Rule__c> productRules = new List<SF_Product_Rule__c>();
    
                for(Product2 product : products) {
                    if(product.Product_Rules__r.size() > 0) {
                        productRules.addAll(product.Product_Rules__r);
                    }
                }
    
                List<SF_Constraint_Rule__c> constraintRules = [SELECT Id, Action__c, Active__c, Priority__c, Product__c, Product__r.Name, Product__r.Is_Bundle__c, Product__r.Stand_Alone__c, Product_Rule__c, Product_Rule__r.Product__c, Product_Rule__r.Product__r.Name, Product_Rule__r.Product__r.Product__c, Product_Rule__r.Product__r.Product__r.Name,Product_Rule__r.Product__r.Is_Bundle__c, Product_Rule__r.Product__r.Stand_Alone__c, Type__c FROM SF_Constraint_Rule__c WHERE Product_Rule__c IN :productRules AND Active__c = TRUE];
    
                
                Map<Id, List<SF_Constraint_Rule__c>> productConstrRules = new Map<Id, List<SF_Constraint_Rule__c>>();
              
                if(constraintRules.size() > 0) {
                    for(SF_Constraint_Rule__c cr : constraintRules) {
                        if(!productConstrRules.containsKey(cr.Product__c)) {
                            productConstrRules.put(cr.Product__c, new List<SF_Constraint_Rule__c>());
                        } 

                        productConstrRules.get(cr.Product__c).add(cr);
                    }

                    //({id: 'wwdw2e22', priority: 4}, {id: 'er23', priority: 2}, {id: 'erfg42', priority: 8})
                    for(Id productId : productConstrRules.keySet()) {
                        List<SF_Constraint_Rule__c> sortedCrsList = new List<SF_Constraint_Rule__c>();

                        for(SF_Constraint_Rule__c cr : productConstrRules.get(productId)) {
                            SF_Constraint_Rule__c highPriority = cr;
                            for(SF_Constraint_Rule__c cr2 : productConstrRules.get(productId)) {
                                if(highPriority.Priority__c <= cr2.Priority__c ) {
                                    highPriority =  highPriority;
                                } else {
                                    highPriority =  cr2;
                                }
                            }

                            sortedCrsList.add(highPriority);
                            productConstrRules.get(productId).remove(productConstrRules.get(productId).indexOf(highPriority));
                        }

                        productConstrRules.get(productId).clear();
                        productConstrRules.get(productId).addAll(sortedCrsList);
                    }

                    System.debug('@@@@@productConstrrules' + productConstrRules);
                    for(Id prodId : productQliMap.keySet()) {
                        System.debug('@@@@key ' + prodId);
                    }
                    for(Id productId : productConstrRules.keySet()) {
                        if(!productQliMap.containsKey(productId)) {
                            System.debug('@@@@ entered in first if');
                            for(SF_Constraint_Rule__c cr : productConstrRules.get(productId)) {
                                String message;
                                String type;
                                if(cr.Action__c == 'Alert') {
                                    if(cr.Type__c == 'Warning') {
                                        message = cr.Product_Rule__r.Product__r.Name + ' does not have ' + cr.Product__r.Name + ' with it, you can add it, however, it is not mandatory';
                                    } else if(cr.Type__c == 'Error') {
                                        message = cr.Product_Rule__r.Product__r.Name + ' does not have ' + cr.Product__r.Name + ' order still can be created, however, it is critial warning';
                                    }

                                    type = cr.Type__c;

                                    buildRepriceMap(cr.Product__r.Name, message, type);
                                } else if(cr.Action__c == 'Validation') {
                                    if(cr.Type__c == 'Warning') {
                                        message = cr.Product_Rule__r.Product__r.Name + ' does not have ' + cr.Product__r.Name + ' with it, however, products validation can still be passed';
                                    } else if(cr.Type__c == 'Error') {
                                        message = cr.Product_Rule__r.Product__r.Name + ' does not have ' + cr.Product__r.Name + ' with it, configure products validation cannot be bypassed without adding ' + cr.Product__r.Name;
                                    }
                                    type = cr.Type__c;

                                    buildRepriceMap(cr.Product__r.Name, message, type);
                                } else if(cr.Action__c == 'Add') {
                                    if(cr.Product__r.Is_Bundle__c && cr.Product__r.Stand_Alone__c == false) {
                                        System.debug('@@@entered in first add if bundle');
                                        bundleProductIds.add(cr.Product__c);

                                        bundleQlisToInsert.add(new SF_Quote_Line_Item__c(Name = cr.Product__r.Name, Product__c = cr.Product__c, SF_Quote__c = quoteId, SF_Price_List_Item__c = SF_QliController.getPli(cr.Product__c), Quantity__c = productQliMap.get(cr.Product_Rule__r.Product__c).Quantity__c, Is_Bundle__c = cr.Product__r.Is_Bundle__c));
                                        System.debug('@@@ bundleProductIds' + bundleProductIds);
                                        System.debug('@@@ bundleQlisToInsert' + bundleQlisToInsert);
                                    } else {
                                        if(cr.Product_Rule__r.Product__r.Is_Bundle__c) {
                                            bundleQlis.add(productQliMap.get(cr.Product_Rule__r.Product__c).Id);

                                            qlisToInsert.add(new SF_Quote_Line_Item__c(Name = cr.Product__r.Name, Quote_Line_Item__c = productQliMap.get(cr.Product_Rule__r.Product__c).Id, Product__c = cr.Product__c, SF_Quote__c = quoteId, SF_Price_List_Item__c = SF_QliController.getPli(cr.Product__c), Quantity__c = productQliMap.get(cr.Product_Rule__r.Product__c).Quantity__c, Is_Bundle__c = cr.Product__r.Is_Bundle__c));
                                        } else {
                                            bundleQlis.add(productQliMap.get(cr.Product_Rule__r.Product__r.Product__c).Id);

                                            qlisToInsert.add(new SF_Quote_Line_Item__c(Name = cr.Product__r.Name, Quote_Line_Item__c = productQliMap.get(cr.Product_Rule__r.Product__r.Product__c).Id, Product__c = cr.Product__c, SF_Quote__c = quoteId, SF_Price_List_Item__c = SF_QliController.getPli(cr.Product__c), Quantity__c = productQliMap.get(cr.Product_Rule__r.Product__c).Quantity__c, Is_Bundle__c = cr.Product__r.Is_Bundle__c));
                                        }

                                    }

                                    message = cr.Product__r.Name + ' was added to ' + cr.Product_Rule__r.Product__r.Name;

                                    type = 'success';

                                    buildRepriceMap(cr.Product__r.Name, message, type);
                                }

                            }
                        } else {
                            for(SF_Constraint_Rule__c cr : productConstrRules.get(productId)) {
                                String message;
                                String type;
                                if(cr.Action__c == 'Remove') {
                                    message = cr.Product__r.Name + ' was deleted since it is not compiatible with ' + cr.Product_Rule__r.Product__r.Name;

                                    type = 'success';

                                    if(productQliMap.get(cr.Product__c).Is_Bundle__c && productQliMap.get(cr.Product__c).Product__r.Stand_Alone__c == false) {
                                        for(SF_Quote_Line_Item__c qli : bundleQliOptionQlisMap.get(productQliMap.get(cr.Product__c).Id)) {
                                            qlisToDelete.add(qli.Id);
                                        }
                                    }

                                    qlisToDelete.add(productQliMap.get(cr.Product__c).Id);

                                    buildRepriceMap(cr.Product__r.Name, message, type);
                                }
                            }
                        }
                    }
                }
        }
    }

        System.debug('@@@bundleQlisToInsert: ' + bundleQlisToInsert);
        if(qlisToInsert.size() > 0 || bundleQlisToInsert.size() > 0 || qlisToDelete.size() > 0) {
            try {
                System.debug('@@@@@@qlis to insert in try block: ' + qlisToInsert);

                insert qlisToInsert;

                Database.SaveResult[] srList = Database.insert(bundleQlisToInsert);

                for (Database.SaveResult sr : srList) {
                    bundleQlisToInsertIds.add(sr.getId());
                }

                Database.delete(qlisToDelete, false);

                insertOptionQlis(bundleQlisToInsertIds, bundleProductIds, quoteId);
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }

        if(qlisToInsert.size() > 0) {
            System.debug('bundleQlis: ' + bundleQlis);
            Map<Id, Double> qlisPricesMap = SF_QliController.computePrices(bundleQlis);
            for(SF_Quote_Line_Item__c qli : qlisToInsert) {
                System.debug('@@@@@@@ in loop ' + qli.Total_Price__c + ' ' + qli.Quantity__c + ' ' + qlisPricesMap.get(qli.Id));
                if(qlisPricesMap.containsKey(qli.Id)) {
                    qli.Total_Price__c = qli.Quantity__c * qlisPricesMap.get(qli.Id);
                }
            }

            try {
                Database.update(qlisToInsert, false);
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }

        List<RepriceData> repriceDataList = new List<RepriceData>();

        for(String pName : repriceRes.keySet()) {
            RepriceData repriceData = new RepriceData();

            repriceData.prodName = pName;
            repriceData.prodRuleData = repriceRes.get(pName);
            repriceDataList.add(repriceData);
        }

        return repriceDataList;
    }

    public static void buildRepriceMap(String productName, String message, String type) {
        if(!repriceRes.containsKey(productName)) {
            repriceRes.put(productName, new List<Map<String, String>>());
        }
        Map<String, String> newMap = new Map<String, String>();
        newMap.put('type', type);
        newMap.put('message', message);

        repriceRes.get(productName).add(newMap);
    }

    public static void insertOptionQlis(List<Id> qlisIds, List<Id> prodIds, Id quoteId) {
        if(qlisIds.size() > 0 && prodIds.size() > 0) {
            System.debug('@@@@entered in insert opton qliss');
            Map<Id, Id> productQliMap = new Map<Id, Id>();
            List<SF_Quote_Line_Item__c> opQlisToInsert = new List<SF_Quote_Line_Item__c>();

            List<SF_Quote_Line_Item__c> bundleQlis = [SELECT Id, Product__c, Name FROM SF_Quote_Line_Item__c WHERE Id IN :qlisIds];
            List<Product2> optionProducts = [SELECT Id, Name, Product__c FROM Product2 WHERE Product__c IN :prodIds AND Optional__c = FALSE];

            for(SF_Quote_Line_Item__c qli : bundleQlis) {
                productQliMap.put(qli.Product__c, qli.Id);
            }

            for(Product2 product : optionProducts) {
                opQlisToInsert.add(new SF_Quote_Line_Item__c(Quote_Line_Item__c = productQliMap.get(product.Product__c), Product__c = product.Id, Quantity__c = 1, SF_Quote__c = quoteId, SF_Price_List_Item__c = SF_QliController.getPli(product.Id)));
            }

            try {
                insert opQlisToInsert;
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }

            Map<Id, Double> qlisPricesMap = SF_QliController.computePrices(qlisIds);
            for(SF_Quote_Line_Item__c qli : opQlisToInsert) {
                if(qlisPricesMap.containsKey(qli.Id)) {
                    qli.Total_Price__c = qli.Quantity__c * qlisPricesMap.get(qli.Id);
                }
            }

            try {
                update opQlisToInsert;
            } catch(DmlException ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }

    public static void deleteQlis(List<Id> qlisIds) {
        List<SF_Quote_Line_Item__c> qlisList = [SELECT Id, Product__c, Is_Bundle__c, SF_Quote__c FROM SF_Quote_Line_Item__c WHERE Id IN :qlisIds];

        List<String> productIds = new List<String>();
        List<String> quoteIds = new List<String>();
        List<String> prodQlisToDelete = new List<String>();
        List<SF_Quote_Line_Item__c> qlisToDelete = new List<SF_Quote_Line_Item__c>();

        if(qlisList != null && qlisList.size() > 0) {
            for(SF_Quote_Line_Item__c qli : qlisList) {
                productIds.add(qli.Product__c);
                quoteIds.add(qli.SF_Quote__c);
            }

            List<SF_Product_Rule__c> productRules = [SELECT Id FROM SF_Product_Rule__c WHERE Product__c IN :productIds];
    
            List<SF_Constraint_Rule__c> constraintRules = [SELECT Id, Product__c, Product_Rule__r.Product__c, Action__c FROM SF_Constraint_Rule__c WHERE Product_Rule__c IN :productRules];
    
            if(constraintRules.size() > 0) {
                for(SF_Constraint_Rule__c cr : constraintRules) {
                    if(productIds.contains(cr.Product_Rule__r.Product__c) && cr.Action__c != 'Remove') {
                        prodQlisToDelete.add(cr.Product__c);
                    }
                }
        
                qlisToDelete = [SELECT Id FROM SF_Quote_Line_Item__c WHERE (Product__c IN :prodQlisToDelete OR Product__r.Product__c IN :prodQlisToDelete) AND SF_Quote__c IN :quoteIds AND Id NOT IN :qlisList];
        
               if(qlisToDelete.size() > 0) {
                    try {
                        delete qlisToDelete;
                    } catch(DmlException ex) {
                        throw new AuraHandledException(ex.getMessage());
                    }
               }
            }
        }   
    }

    //productName: ({type: 'warning', message: 'some random message'}, {type: 'warning', message: 'some random message'})
    public class RepriceData {
        @AuraEnabled public String prodName {get; set;}
        @AuraEnabled public List<Map<String, String>> prodRuleData  {get; set;}
    }
}
