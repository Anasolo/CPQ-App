trigger SF_QuoteLineItemTrigger on SF_Quote_Line_Item__c (after delete) {
    List<SF_Quote_Line_Item__c> qlis = new List<SF_Quote_Line_Item__c>();

    if(Trigger.isAfter && Trigger.isDelete) {
        for(SF_Quote_Line_Item__c qli : Trigger.old) {
            if(!Trigger.newMap.containsKey(qli.Id)) {
                qlis.add(qli);
            }
        }
        System.debug('@@@@@ qlis to delete: ' + qlis);
        SF_QliTriggerHelper.deleteQlis(qlis);
    }
}