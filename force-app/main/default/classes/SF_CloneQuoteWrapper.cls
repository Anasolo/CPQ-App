/* This class is a wrapper class for Clone Quote class.
    We need this to have multiple parameters for method
    to invoke in flow */
public class SF_CloneQuoteWrapper {

    @InvocableVariable(required=true)
    public ID quoteId;
    
    @InvocableVariable(required=true)
    public Boolean includeQLI;

}