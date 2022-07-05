public class SF_CloneQuote {
    
    @InvocableMethod(label='Clone Quotes')
    public static List<SF_Quote__c> cloneQuote(List<SF_CloneQuoteWrapper> wrapperVars){

        System.debug('@@@@@@@@@@@ ---- wrapperVars ' + wrapperVars);
        
        // Query fields from mdt
        Clone_Quote_Fields_Mapping__mdt[] cloneFields = [SELECT Fields__c, QualifiedApiName  FROM Clone_Quote_Fields_Mapping__mdt];
        
        System.debug('@@@@@@@@@@@@------ cloneFields ' + cloneFields);

        Set<String> newQuoteFields = new Set<String>();
        Set<String> newQliFields = new Set<String>();
        Id idFromQuote = wrapperVars[0].quoteId;
        
        // Group mdt fields by records (Clone Quote Fields and Clone QLI Fields)
        for(Clone_Quote_Fields_Mapping__mdt quoteF: cloneFields){
            
            if(quoteF.QualifiedApiName == 'Quote_fields'){
                newQuoteFields.addAll(quoteF.Fields__c.split(','));
            }
            else if(quoteF.QualifiedApiName == 'Quote_Line_Item_fields'){
                newQliFields.addAll(quoteF.Fields__c.split(','));
            }
        }
        System.debug('@@@@@@@@@@@@------ newQliFields ' + newQliFields);
        System.debug('@@@@@@@@@@@@------ newQuoteFields ' + newQuoteFields);


        // Join values of Set to use in a dynamic query
        String joinedQuoteFields = String.join(new List<String>(newQuoteFields), ', ');
        String joinedQliFields = String.join(new List<String>(newQliFields), ', ');

        // Query existing quote fields which we are clonning
        SF_Quote__c existingQuote = Database.query('Select ' + joinedQuoteFields + ' From SF_Quote__c WHERE Id =:idFromQuote');
        
        System.debug('@@@@@@@@@@@@------ existingQuote ' + existingQuote);


        // Query existing QLI fields which we are clonning
        List<SF_Quote_Line_Item__c> existingQli = Database.query('Select ' + joinedQliFields + ' From SF_Quote_Line_Item__c WHERE SF_Quote__c =:idFromQuote');
        
        System.debug('@@@@@@@@@@@@------ existingQli ' + existingQli);


        // Create clonned Quote
        SF_Quote__c createCloneQuote = new SF_Quote__c();
        
        for(String field : newQuoteFields){
            createCloneQuote.put(field, existingQuote.get(field));
        }

        System.debug('@@@@@@@@@@@@------ createCloneQuote ' + createCloneQuote);

        
        Insert createCloneQuote;

        
        // Clone QLI or not
        if(wrapperVars[0].includeQLI == true){

        // Add to be inserted QLIs in this list        
        List<SF_Quote_Line_Item__c> insertQlis = new List<SF_Quote_Line_Item__c>();
                
        for(SF_Quote_Line_Item__c qli: existingQli ){

            SF_Quote_Line_Item__c cloneQli = new SF_Quote_Line_Item__c();
            
            for(String field : newQliFields){

                cloneQli.put(field, qli.get(field));
                cloneQli.SF_Quote__c = createCloneQuote.Id;

            }
            insertQlis.add(cloneQli);

        }
        System.debug('@@@@@@@@@@@@------ insertQlis ' + insertQlis);

       Insert insertQlis;

        }
        return new List<SF_Quote__c> {createCloneQuote};
    }
}