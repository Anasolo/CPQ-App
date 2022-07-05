/*  This method updates incoming quote's status to Accepted */

public class SF_AcceptQuote {
    
    @AuraEnabled
    public static void AcceptQuote(Id quoteId) {
        
        SF_Quote__c quoteToUpdate = new SF_Quote__c();
        quoteToUpdate.Id = quoteId;
        quoteToUpdate.Status__c = 'Accepted';
        
        update quoteToUpdate;
    }
}