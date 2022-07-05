public class SF_CreateOrderHelper {
    // When quote status becomes 'Accepted' from other status, Order and Order Products are created and activated.
    // When creating Order - Shipping and Billing Adresses, Total Prices, Number Of Order Products, 
    // Activate Date, Order End Date, Account and Opportunity fields have to be filled.
    @future
    public static void orderCreationOnAcceptedQuote(List<Id> quoteId){
        
        final List<SF_Order__c> newOrders = new List<SF_Order__c>();
        final List<SF_Order_Product__c> newOrderProducts = new List<SF_Order_Product__c>();
        final Map<ID, SF_Order__c> quoteOrderMap = new Map<ID, SF_Order__c>();        
        
        
        // Query quote and related line items from incoming Id
        List<SF_Quote__c> acceptedQuotes = [SELECT Id,
                                            Account__c,
                                            Contact__c,
                                            Opportunity__c,
                                            Total_Price__c,
                                            NO_Line_Items__c,
                                            Shipping_Country__c,
                                            Shipping_Postal_Code__c,
                                            Shipping_State__c,
                                            Shipping_Street__c,
                                            Billing_Country__c,
                                            Billing_Postal_Code__c,
                                            Billing_State__c,
                                            Billing_Street__c,
                                            (SELECT Id,  Name, Quantity__c, Product__c,
                                             SF_Price_List_Item__c, Total_Price__c, Unit_Price__c 
                                             FROM SF_Quote_Line_Items__r)
                                            FROM SF_Quote__c 
                                            WHERE Id IN :quoteId];
        
        
        // For every accepted quote create order, clone field values from quote and store new order with quote id in Map
        for(SF_Quote__c quotes: acceptedQuotes){
            
            SF_Order__c newOrder = new SF_Order__c(Account__c = quotes.Account__c,
                                                   Opportunity__c = quotes.Opportunity__c,
                                                   Quote__c = quotes.Id,
                                                   Contact__c = quotes.Contact__c,
                                                   Status__c = 'Activated',
                                                   Active__c = true,
                                                   NO_Order_Products__c = quotes.NO_Line_Items__c,
                                                   Activated_Date__c = System.today(),
                                                   Order_Start_Date__c = System.today(),
                                                   Order_End_Date__c = System.today().addDays(7),
                                                   Shipping_Country__c = quotes.Shipping_Country__c,
                                                   Shipping_Postal_Code__c = quotes.Shipping_Postal_Code__c,
                                                   Billing_Country__c = quotes.Billing_Country__c,
                                                   Billing_Postal_Code__c = quotes.Billing_Postal_Code__c,
                                                   Billing_State__c = quotes.Billing_State__c,
                                                   Billing_Street__c = quotes.Billing_Street__c);
            newOrders.add(newOrder);
            quoteOrderMap.put(quotes.Id, newOrder);       
        }
        insert newOrders;
        
        // Get the order from Map and check if quote has any line items, create order product
        for(SF_Quote__c quote : acceptedQuotes){
            
            SF_Order__c order = quoteOrderMap.get(quote.Id);
            
            if(quote.SF_Quote_Line_Items__r != null && !quote.SF_Quote_Line_Items__r.isEmpty()){
                
                for(SF_Quote_Line_Item__c qli : quote.SF_Quote_Line_Items__r){
                    SF_Order_Product__c newOrderProduct = new SF_Order_Product__c(Order__c = order.Id, 
                                                                                  Name = qli.Name,
                                                                                  Start_Date__c = System.today(),
                                                                                  End_Date__c = System.today().addDays(7),
                                                                                  Product__c = qli.Product__c, 
                                                                                  Quantity__c = qli.Quantity__c,
                                                                                  Total_Price__c = qli.Total_Price__c,
                                                                                  Unit_Price__c = qli.Unit_Price__c,
                                                                                  Status__c = 'Activated');
                    newOrderProducts.add(newOrderProduct);
                }
            }   
        }        
        insert newOrderProducts;        
    }
}