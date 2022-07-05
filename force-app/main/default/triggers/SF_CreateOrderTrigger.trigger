/* 	 This trigger creates and activates Order and Order Products
when quote status becomes 'Accepted'.
*/
trigger SF_CreateOrderTrigger on SF_Quote__c (after update) {
    
    // Call the method only if the old and new values of status field was not 'Accepted' and became 'Accepted
    if(Trigger.isAfter && Trigger.isUpdate){
        List<Id> quoteId = new List<Id>();
        
        for (SF_Quote__c newValue : Trigger.new) {
            SF_Quote__c oldValue = Trigger.oldMap.get(newValue.Id);
            if(oldValue.Status__c != 'Accepted' && newValue.Status__c == 'Accepted'){
                quoteId.add(newValue.Id);
            }
        }
        if(!quoteId.isEmpty()){
            SF_CreateOrderHelper.orderCreationOnAcceptedQuote(quoteId);
        }
    }
}