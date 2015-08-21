# -*- coding: utf-8 -*-
#!/usr/bin/env python

from appium import webdriver
import time
import os
import unittest
from time import sleep
import constants as const
import loginView
import filesView
import settingsView
import actions

class createFolderTest(unittest.TestCase):

    def setUp(self):
        # set up appium
        self.driver = actions.getWebDriver()
        #self.driver.implicitly_wait(60)

    def tearDown(self):
        self.driver.quit()

    def test_create_folder_ok(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        sleep(1)
        #self.driver.find_element_by_name("Add").click()
        #sleep(1)
        #self.driver.find_element_by_name("New folder").click()
        #sleep(1)
        #self.driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[3]/UIAAlert[1]/UIAScrollView[1]/UIATableView[1]/UIATableCell[1]/UIATextField[1]").set_value("aHola")
        #self.driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[3]/UIAAlert[1]/UIACollectionView[1]/UIACollectionCell[2]").click()
        #sleep(3)
        
        #this works
        #cellName = self.driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[1]/UIATableView[1]/UIATableCell[2]").get_attribute("name")
        
        cellsNumber = self.driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[1]/UIATableView[1]").cells

        #self.assertEqual(self.driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[1]/UIATableView[1]/UIATableCell[2]").get_attribute("name"), "aHola")
        import ipdb; ipdb.set_trace()
        sleep(3)
        
        #import ipdb; ipdb.set_trace()

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(createFolderTest)
    unittest.TextTestRunner(verbosity=2).run(suite)