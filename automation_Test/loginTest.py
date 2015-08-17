# -*- coding: utf-8 -*-
#!/usr/bin/env python

from appium import webdriver
import time
import os
import unittest
from time import sleep
import constants as const
import actions

class loginTest(unittest.TestCase):

    def setUp(self):
        # set up appium
        self.driver = actions.getWebDriver()
        #self.driver.implicitly_wait(60)

    def tearDown(self):
        self.driver.quit()

    def test_ui_login_ok(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        actions.assert_is_in_files_view(self)
        #import ipdb; ipdb.set_trace()

    def test_ui_login_incorrect_password(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_WRONG_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        actions.assert_is_not_in_files_view(self)
        self.assertEqual(self.driver.find_elements_by_class_name("UIAStaticText")[1].get_attribute("name"), "The user or password is incorrect")
        #import ipdb; ipdb.set_trace()

    def test_ui_multiaccount(self):
        driver = self.driver
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        actions.assert_is_in_files_view(self)

        settingsButton =  driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[1]/UIATabBar[1]/UIAButton[4]");
        self.assertEqual(settingsButton.get_attribute("name"), "Settings")
        settingsButton.click();

        addNewAccountButton = driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[1]/UIATableView[1]/UIATableCell[2]/UIAStaticText[1]")
        self.assertEqual(addNewAccountButton.get_attribute("name"), "Add new account")
        addNewAccountButton.click()

        actions.doLoginWith(self,const.K_URL_2,const.K_USER_2,const.K_PASSWORD_2,const.K_SELF_SIGNED_2)
        actions.assert_is_in_files_view(self)



if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(loginTest)
    unittest.TextTestRunner(verbosity=2).run(suite)