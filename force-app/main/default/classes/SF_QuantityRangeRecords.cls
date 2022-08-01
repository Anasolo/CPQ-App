// Class for LWC SF_QuantityRange to get SF_Quantity_Range__c records
public class SF_QuantityRangeRecords {
    @AuraEnabled(cacheable=true)
    public static List<SF_Quantity_Range__c> getRangeRecords(Id pli){
        
        return [SELECT Id, Range__c, Quantity_From__c, Price__c, Price_List_Item__c 
                FROM SF_Quantity_Range__c
                WHERE Price_List_Item__c = :pli];
    }
}