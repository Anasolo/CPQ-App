/**
* ============================================
* @claseName: SF_ScheduledFieldsInfoCaching
* @description: This class is caching fields info which is used in sf_configureProducts.lwc
* @author: Jubo M.
* @testClass: SF_ScheduledFIieldsInfoCachingTest
* @dateCreated: 22/06/2022
* @lastChange: 22/06/2022 by Jubo M.
* ============================================ 
*/
global class SF_ScheduledFieldsInfoCaching implements Schedulable {
    global void execute(SchedulableContext SC) {
        List<String> fieldNames = SF_Utils.getFieldApiNames('Fields For Configure Products LWC');
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType qliSchema = schemaMap.get('SF_Quote_Line_Item__c');
        Map<String, Schema.SObjectField> fieldsMap = qliSchema.getDescribe().fields.getMap();

        Map<String, Map<String, String>> fieldLabelsApiNamesMap = new Map<String, Map<String, String>>();

        for(String fieldName : fieldNames) {
            try {
                fieldLabelsApiNamesMap.put(fieldName.deleteWhitespace(), new Map<String, String>());
                fieldLabelsApiNamesMap.get(fieldName.deleteWhitespace()).put('label', fieldsMap.get(fieldName.deleteWhitespace()).getDescribe().getLabel());
                Schema.DisplayType dType = fieldsMap.get(fieldName.deleteWhitespace()).getDescribe().getType();
                String fieldType = String.valueOf(dType);
				fieldLabelsApiNamesMap.get(fieldName.deleteWhitespace()).put('datatype', fieldType);
			} catch(Exception e){
    			 System.debug('Exception: ' + e.getMessage() + ' --- ' + e.getStackTraceString());
			}
        }

        Cache.Org.put('local.ConifgProductsFielldsInfoPart.fieldsInfo', fieldLabelsApiNamesMap);
    }
 }