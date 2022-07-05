/**
* ============================================
* @claseName: UserManager
* @description: This is User Manager class
* @author: Jubo M.
* @testClass: SF_UserManagerTest
* @dateCreated: 22/06/2022
* @lastChange: 22/06/2022 by Jubo M.
* ============================================ 
*/
public without sharing class UserManager {
    /**
    * @author: Jubo M.
    * @description: This method returns current User's info
    */ 
    @AuraEnabled(cacheable=true)
    public static user getUserInfo() {
        String userId = UserInfo.getUserId();
        return [SELECT Id, Profile.Name From User WHERE ID =: userId LIMIT 1];
    }
}