/**
* ============================================
* @claseName: SF_PlatformCacheData
* @description: This class takes care of caching frequently referenced data by users 
* @author: Jubo M.
* @testClass: 
* @dateCreated: 22/06/2022
* @lastChange: 23/06/2022 by Jubo M.
* ============================================ 
*/
public with sharing class SF_PlatformCacheData {
    /**
    * @author: Jubo M.
    * @description: This method returns cached fields config info, teh fields which should be used in sf_configureProducts.lwc
    */   
    public static Map<String, Map<String, String>> getCachedConfigProductsFieldsInfo(String objName, List<String> fieldNames) {
        Map<String, Map<String, String>> cachedFieldsInfo = (Map<String, Map<String, String>>)Cache.Org.get('local.ConifgProductsFielldsInfoPart.fieldsInfo');

        if(cachedFieldsInfo == null || cachedFieldsInfo.isEmpty()) {
            cachedFieldsInfo = refreshCachedConfigProductsFieldsInfo(objName, fieldNames);
        }

        return cachedFieldsInfo;
    }

    /**
    * @author: Jubo M.
    * @description: This method is refreshing the cached data
    */   
    public static Map<String, Map<String, String>> refreshCachedConfigProductsFieldsInfo(String objName, List<String> fieldNames) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType qliSchema = schemaMap.get(objName);
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
        
        return (Map<String, Map<String, String>>) Cache.Org.get('local.ConifgProductsFielldsInfoPart.fieldsInfo');
    }
}