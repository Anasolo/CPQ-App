public with sharing class SF_PrimaryQuoteTriggerHandler {

    public static boolean insertFired = false;
    public static boolean updateFired = false;
    public static void validatePrimaryQuote(List<SF_Quote__c> quoteList, Boolean isInsert, Boolean isUpdate, Boolean isDelete, List<SF_Quote__c> quotesOld){

         
        if(isInsert){

        	Set<Id> oppIds = new Set<Id>();
        	Map<Id, List<SF_Quote__c>> oppQuotesMap = new Map<Id, List<SF_Quote__c>>();
        	List<SF_Quote__c> quotesToUpdate = new List<SF_Quote__c>();
        
            // collect the Quotes by their Ids in Map
            for(SF_Quote__c q : quoteList) {
                oppIds.add(q.Opportunity__c);
                if(!oppQuotesMap.containsKey(q.Opportunity__c)) {
                    oppQuotesMap.put(q.Opportunity__c, new List<SF_Quote__c>());
                }
                oppQuotesMap.get(q.Opportunity__c).add(q);
            }
            // if quotes exist with primary and if new quote is primary, uncheck other primary and check new one.
         	List<SF_Quote__c> quotes = [SELECT Id, Opportunity__c, Primary__c FROM SF_Quote__c WHERE Opportunity__c IN :oppIds AND Primary__c = TRUE];
            if(quotes.size() > 0) {
                for(SF_Quote__c q : quotes) {
            		if(oppIds.contains(q.Opportunity__c)) {
                        for(SF_Quote__c qq : oppQuotesMap.get(q.Opportunity__c)) {
                            if(qq.Primary__c == true) {
                                q.Primary__c = false;
                                quotesToUpdate.add(q);
							}
                        }
            		}
        		}
                // if quotes on oppty is empty, first quote will be primary
            } else {
                quoteList[0].Primary__c = true;
            }
        	update quotesToUpdate;
                		
        // on update - find existing quote and check as primary, uncheck old one. also make sure user can't uncheck primary status
        } else if(isUpdate){
            Set<Id> oppIds = new Set<Id>();
        	Map<Id, List<SF_Quote__c>> oppQuotesMap = new Map<Id, List<SF_Quote__c>>();
            List<SF_Quote__c> quotesToUpdate = new List<SF_Quote__c>();
            
            for(SF_Quote__c q : quoteList) {
                oppIds.add(q.Opportunity__c);
                if(!oppQuotesMap.containsKey(q.Opportunity__c)) {
                    oppQuotesMap.put(q.Opportunity__c, new List<SF_Quote__c>());
                }
                oppQuotesMap.get(q.Opportunity__c).add(q);
            }
            // update existing quote, if user wants to check quote as primary, check and uncheck the old one
            List<SF_Quote__c> quotes = [SELECT Id, Opportunity__c, Primary__c FROM SF_Quote__c WHERE Opportunity__c IN :oppIds AND Primary__c = TRUE];
            
            for(SF_Quote__c q : quoteList) {
                if(q.Primary__c == true) {
                    for(SF_Quote__c qq : quotes) {
                        if(qq.Id != q.Id && qq.Primary__c == true) {
                            qq.Primary__c = false;
                            quotesToUpdate.add(qq);
                        }
                    }
                } else if(q.Primary__c == false) {
                    for(SF_Quote__c oldQ : quotesOld) {
                        if(oldQ.Id == q.Id && oldQ.Primary__c == true) {
                            q.addError(System.label.UncheckPrimaryError);
                        }
                    }
                }
            }

            if(quotesToUpdate.size() > 0) {
                System.debug('quotes size: ' + quotesToUpdate.size());
                update quotesToUpdate;
            }
        } else if(isDelete){
            for(SF_Quote__c q : quoteList) {
                if(q.Primary__c == true) {
                    q.addError(System.label.QuoteTriggerDeleteError);
                }
            }
        }
    }
}