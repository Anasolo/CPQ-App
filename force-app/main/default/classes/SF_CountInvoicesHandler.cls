// Helper class for SF_CountInvoices
// Method has to increase the number of NO_Invoices__c field on every inserted Invoice
public class SF_CountInvoicesHandler {
    
    public static void numOfInvoices(List<SF_Invoice__c> invoices){
        
        Map<Id, List<SF_Invoice__c>> orderInvoiceMap = new Map<Id, List<SF_Invoice__c>>();
        
        List<SF_Order__c> ordersToUpdate = new List<SF_Order__c>();
        
        // Add invoices to Map with Id and Invoices
        for (SF_Invoice__c inv : invoices) {
            if(orderInvoiceMap.containsKey(inv.Order__c)){
                orderInvoiceMap.get(inv.Order__c).add(inv);
            }else{
                orderInvoiceMap.put(inv.Order__c, new List<SF_Invoice__c>{inv});
            }        
        }
        
        // Update NO_Invoices__c field value by assigning the number of Invoices on Order from Map
        for(ID ord: orderInvoiceMap.keySet()){
           	SF_Order__c order = new SF_Order__c(
            Id = ord,
            NO_Invoices__c = orderInvoiceMap.get(ord).size()
            );
            ordersToUpdate.add(order);
        }
        update ordersToUpdate;
    }
}