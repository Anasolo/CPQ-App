/**
* ============================================
* @claseName: SF_Utils
* @description: This is Utils class
* @author: Jubo M.
* @dateCreated: 28/05/2022
* @lastChange: 23/06/2022 by Jubo M.
* ============================================ 
*/
public with sharing class SF_Utils {
     /**
    * @author: Jubo M.
    * @description: This method returns List of the field api names according to given custom metadata types record
    */   
    public static List<String> getFieldApiNames(String mdtRecordName) {
        List<FieldsConfig__mdt> fieldsConfig = [SELECT Id, Fields__c FROM FieldsConfig__mdt WHERE Label = :mdtRecordName LIMIT 1];

        List<String> fieldApiNames = new List<String>();
        
        if(fieldsConfig.size() > 0 && !String.isBlank(fieldsConfig[0].Fields__c)) {
            fieldApiNames = fieldsConfig[0].Fields__c.split(',');
        }

        return fieldApiNames;
    }
}