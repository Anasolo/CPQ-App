/**
* ============================================
* @claseName: SF_UserManagerTest
* @description: This class tests SF_LookUpController
* @author: Jubo M.
* @Class: UserManager
* @dateCreated: 24/06/2022
* @lastChange: 24/06/2022 by Jubo M.
* ============================================ 
*/
@isTest
public with sharing class SF_UserManagerTest {
     /**
    * @author: Jubo M.
    * @description: This method tests UserManager.getUserInfo method
    */ 
    @isTest
    public static void testGetUserInfo() {
        String userId = UserInfo.getUserId();

        System.assertEquals(userId, UserManager.getUserInfo().Id, 'User Ids do not match');
    }
}