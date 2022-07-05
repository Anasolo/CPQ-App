/**
* ============================================
* @claseName: SF_ScheduledFIieldsInfoCachingTest
* @description: This class tests SF_LookUpController
* @author: Jubo M.
* @Class: SF_ScheduledFieldsInfoCaching
* @dateCreated: 24/06/2022
* @lastChange: 24/06/2022 by Jubo M.
* ============================================ 
*/
@isTest
public with sharing class SF_ScheduledFIieldsInfoCachingTest {
     /**
    * @author: Jubo M.
    * @description: This method tests execute method of SF_ScheduledFieldsInfoCaching class
    */ 
    @isTest
    public static void testExecuteFieldsInfoCaching() {
        SF_ScheduledFieldsInfoCaching scj = new SF_ScheduledFieldsInfoCaching();

        Test.startTest();
        scj.execute(null);
        Test.stopTest();

        Map<String, Map<String, String>> cachedFiedlsInfo = (Map<String, Map<String, String>>) Cache.Org.get('local.ConifgProductsFielldsInfoPart.fieldsInfo');

        System.assert(cachedFiedlsInfo.keySet().size() > 0, 'Caching did not happen');
    }
}