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
import webdavCommands

class createFolderTest(unittest.TestCase):

    def setUp(self):
        # set up appium
        self.driver = actions.getWebDriver()
        webdavCommands.deleteFile(const.K_URL_1, const.K_USER_1, const.K_PASSWORD_1, const.K_FOLDER_NAME)
        #self.driver.implicitly_wait(60)

    def tearDown(self):
        self.driver.quit()
        webdavCommands.deleteFile(const.K_URL_1, const.K_USER_1, const.K_PASSWORD_1, const.K_FOLDER_NAME)

    def test_create_folder_ok(self):

        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        sleep(1)
        self.driver.find_element_by_name(filesView.addButton_name).click()
        sleep(1)
        self.driver.find_element_by_name(filesView.createFolder_name).click()
        sleep(1)
        self.driver.find_element_by_xpath(filesView.createFolderTextView_xpath).set_value(const.K_FOLDER_NAME)
        self.driver.find_element_by_name(filesView.saveButton_name).click()
        sleep(30)
        
        cellName = (self.driver.find_element_by_xpath(filesView.filesTableView_xpath).find_elements_by_class_name(filesView.cell_class))[2].get_attribute(filesView.name_attribute)
        allCells = self.driver.find_element_by_xpath(filesView.filesTableView_xpath).find_elements_by_class_name(filesView.cell_class)

        isExistByUserInterface = False
        isExistByWebDav = False

        for currentCell in allCells:

            if const.K_FOLDER_NAME == currentCell.get_attribute(filesView.name_attribute).encode('utf-8'):
                isExistByUserInterface = True

        isExistByWebDav = webdavCommands.isFile(const.K_URL_1, const.K_USER_1, const.K_PASSWORD_1, const.K_FOLDER_NAME)

        if isExistByWebDav and isExistByUserInterface:
            self.assertTrue(True)
        else:
            self.assertTrue(False)
        
        #import ipdb; ipdb.set_trace()

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(createFolderTest)
    unittest.TextTestRunner(verbosity=2).run(suite)