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

        actions.doLoginWith(self,server_url,user,password,ssl)
        sleep(1)

        class_to_check = 'UIATabBar'
        time_out = 20
        sleep_time = 1
        expected_class_found = 1
        actions.wait_until(actions.check_values_by_class_name, time_out, sleep_time, self.driver, class_to_check, expected_class_found)

        self.assertTrue(actions.check_values_by_class_name(self.driver, class_to_check, expected_class_found))
        #import ipdb; ipdb.set_trace()

    def test_ui_login_incorrect_password(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_WRONG_1
        ssl = const.K_SELF_SIGNED_1

        actions.doLoginWith(self,server_url,user,password,ssl)
        sleep(1)

        class_to_check = 'UIATabBar'
        time_out = 20
        sleep_time = 1
        expected_class_found = 0
        actions.wait_until(actions.check_values_by_class_name, time_out, sleep_time, self.driver, class_to_check, expected_class_found)

        self.assertTrue(actions.check_values_by_class_name(self.driver, class_to_check, expected_class_found))
        self.assertEqual(self.driver.find_elements_by_class_name("UIAStaticText")[1].get_attribute("name"), "The user or password is incorrect")
        #import ipdb; ipdb.set_trace()

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(loginTest)
    unittest.TextTestRunner(verbosity=2).run(suite)