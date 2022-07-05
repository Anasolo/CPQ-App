// This class creates Invoice and Invoice Line Items if there is none on created Order, which has Status - Activated.
public class SF_CreateInvoice implements Database.Batchable<sObject>, Schedulable{
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the Orders with Activated Status to pass to execute.
        return Database.getQueryLocator([
            SELECT  Id, 
            Name, 
            Account__c, 
            Activated_Date__c, 
            Contact__c, 
            Opportunity__r.Name,
            Order_Amount__c,
            Order_Start_Date__c, 
            Order_End_Date__c,
            NO_Order_Products__c,
            CurrencyIsoCode
            FROM    SF_Order__c
            WHERE   Status__c = 'Activated'
            AND NO_Invoices__c = 0
        ]);
    }
    public void execute(Database.BatchableContext bc, List<SF_Order__c> orders){
        
        Map<Id, SF_Invoice__c> newInvoices = new Map<Id, SF_Invoice__c>();
        
        // For every Order with no Invoice, create New Invoice
        for(SF_Order__c ord: orders){
            SF_Invoice__c createInvoice = new SF_Invoice__c(
                Account__c = ord.Account__c,
                Order__c = ord.Id,
                Name = ord.Name,
                Status__c = 'Draft',
                Opportunity_Name__c  = ord.Opportunity__r.Name,
                Invoice_Date__c = ord.Order_Start_Date__c,
                Invoice_Posted_Date__c = ord.Order_End_Date__c
                // invoce amount
                
            );
            // list to insert invoices
            newInvoices.put(ord.Id, createInvoice);
        }        
        
        // If to be inserted Invoice Map is not empty, insert Invoices for Orders
        insert newInvoices.values();
        
        // Creating Invoice Line Items for Order Products
        List<SF_Invoice_Line__c> insertInvoiceLine = new List<SF_Invoice_Line__c>();
        
        // Query Order Products of incoming Orders
        List<SF_Order_Product__c> orderProducts = [SELECT Id, Name, Order__c, Product__c, End_Date__c, Start_Date__c
                                                   FROM SF_Order_Product__c 
                                                   WHERE Order__c IN :orders];
        
        // Create Invoice Line Items for Order Products
        for(SF_Order_Product__c ordProd : orderProducts){
            SF_Invoice_Line__c newInvoiceLine = new SF_Invoice_Line__c(
                SF_Invoice__c = newInvoices.get(ordProd.Order__c).Id,
                Status__c = 'Draft',
                Product__c = ordProd.Product__c,
                SF_Order_Product__c = ordProd.Id,
                Start_Date__c = ordProd.Start_Date__c,
                End_Date__c = ordProd.End_Date__c
            );
            insertInvoiceLine.add(newInvoiceLine);
        }        
        insert insertInvoiceLine;        
    }
    
    public void finish(Database.BatchableContext bc){
    }
    public void execute (SchedulableContext SC) {
        Database.executeBatch(new SF_CreateInvoice());
    }
}