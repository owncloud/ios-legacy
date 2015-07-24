from appium import webdriver
import time
import os
import unittest
from time import sleep
import constant as const
import actions

class loginTest(unittest.TestCase):

    def setUp(self):
        # set up appium
        desired_caps = {}
        desired_caps['appium-version'] = const.K_APPIUM_VER
        desired_caps['platformName'] = const.K_APP_PLATFORM_NAME
        desired_caps['platformVersion'] = const.K_APP_PLATFORM_VER
        desired_caps['deviceName'] = const.K_DEVICE_NAME
        #desired_caps['app'] = os.path.dirname(os.path.realpath(__file__)) + const.K_APP_FILE_NAME
        desired_caps['app'] = os.path.abspath(const.K_APP_FILE_NAME)
        desired_caps['udid'] = 'c45487fe52e63da068ba43e41755a165e84f0f0d'
        self.driver = webdriver.Remote('http://0.0.0.0:4723/wd/hub', desired_caps)
        #self.driver.implicitly_wait(60)


    def tearDown(self):
        self.driver.quit()

    def test_ui_login_ok(self):
        server_url = "docker.oc.solidgear.es:51222"
        user = "gon"
        password = "gon"
        ssl = True

        actions.doLoginWith(self.driver,server_url,user,password,ssl)

        sleep(3)

        self.assertEqual(len(self.driver.find_elements_by_class_name('UIATabBar')), 1)
        #import ipdb; ipdb.set_trace()

    def test_ui_login_noOk(self):
        server_url = "docker.oc.solidgear.es:51222"
        user = "gon"
        password = "go"
        ssl = True

        actions.doLoginWith(self.driver,server_url,user,password,ssl)

        sleep(3)

        self.assertEqual(len(self.driver.find_elements_by_class_name('UIATabBar')), 0)
        #import ipdb; ipdb.set_trace()

#if __name__ == '__main__':
#    suite = unittest.TestLoader().loadTestsFromTestCase(loginTest)
#    unittest.TextTestRunner(verbosity=2).run(suite)