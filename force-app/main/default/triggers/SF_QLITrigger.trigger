/*
 * ============================================
 * @triggerName: SF_QLITrigger.trigger
 * @description: Trigger for SF_Quote_Line_Item__c object
 * @author: Jubo M.
 * @testClass: SF_QLITriggerTest
 * @since: 20/05/2022
 * ============================================
*/
trigger SF_QLITrigger on SF_Quote_Line_Item__c (before insert) {
	if(Trigger.isBefore && Trigger.isInsert) {
        SF_QLI_Trigger_Helper.setQliValues(Trigger.new);
    } 
}