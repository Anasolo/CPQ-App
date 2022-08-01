public with sharing class SF_QliTriggerHelper {
    public static void deleteQlis(List<SF_Quote_Line_Item__c> qlisList) {
        List<String> productIds = new List<String>();
        List<String> quoteIds = new List<String>();
        List<String> prodQlisToDelete = new List<String>();
        List<SF_Quote_Line_Item__c> qlisToDelete = new List<SF_Quote_Line_Item__c>();

        for(SF_Quote_Line_Item__c qli : qlisList) {
            productIds.add(qli.Product__c);
            quoteIds.add(qli.SF_Quote__c);
        }

        List<SF_Product_Rule__c> productRules = [SELECT Id FROM SF_Product_Rule__c WHERE Product__c IN :productIds];

        List<SF_Constraint_Rule__c> constraintRules = [SELECT Id, Product__c, Product_Rule__r.Product__c, Action__c FROM SF_Constraint_Rule__c WHERE Product_Rule__c IN :productRules];

        for(SF_Constraint_Rule__c cr : constraintRules) {
            if(productIds.contains(cr.Product_Rule__r.Product__c) && cr.Action__c != 'Remove') {
                prodQlisToDelete.add(cr.Product__c);
            }
        }

        qlisToDelete = [SELECT Id FROM SF_Quote_Line_Item__c WHERE Product__c IN :prodQlisToDelete AND SF_Quote__c IN :quoteIds];

        try {
            delete qlisToDelete;
        } catch(DmlException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
