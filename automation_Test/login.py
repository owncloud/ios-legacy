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

        actions.doLoginWith(self.driver,server_url,user,password,ssl)

        sleep(3)

        self.assertEqual(len(self.driver.find_elements_by_class_name('UIATabBar')), 1)
        #import ipdb; ipdb.set_trace()

    def test_ui_login_noOk(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_WRONG_1
        ssl = const.K_SELF_SIGNED_1

        actions.doLoginWith(self.driver,server_url,user,password,ssl)

        sleep(3)

        self.assertEqual(len(self.driver.find_elements_by_class_name('UIATabBar')), 0)
        #import ipdb; ipdb.set_trace()

#if __name__ == '__main__':
#    suite = unittest.TestLoader().loadTestsFromTestCase(loginTest)
#    unittest.TextTestRunner(verbosity=2).run(suite)