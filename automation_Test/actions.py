# -*- coding: utf-8 -*-
#!/usr/bin/env python

import time
import os
from time import sleep
import constants as const
import loginView
import helpGuideView
import filesView
from appium import webdriver

def getWebDriver():
    wd = None
    desired_caps = {}
    desired_caps['appium-version'] = const.K_APPIUM_VER
    desired_caps['platformName'] = const.K_APP_PLATFORM_NAME
    desired_caps['platformVersion'] = const.K_APP_PLATFORM_VER
    desired_caps['deviceName'] = const.K_DEVICE_NAME
    desired_caps['app'] = os.path.dirname(os.path.realpath(__file__)) + const.K_APP_FILE_NAME
    wd = webdriver.Remote(const.K_WD_REMOTE_URL, desired_caps)
    wd.implicitly_wait(const.K_WD_EXPLICITY_WAIT)
    return wd

def doFirstLoginWith(self,server,user,password, ssl):
    driver = self.driver

    skipButtonInHelpGuide = driver.find_elements_by_class_name(helpGuideView.skipButton_class)[helpGuideView.skipButton_index]
    self.assertEqual(skipButtonInHelpGuide.get_attribute("name"), helpGuideView.skipButton_name)
    skipButtonInHelpGuide.click()

    doLoginWith(self,server,user,password,ssl)

def doLoginWith(self,server,user,password, ssl):
    driver = self.driver

    user_field = driver.find_elements_by_class_name(loginView.user_field_class)[loginView.user_field_index]
    user_field.clear()
    user_field.set_value(user)

    pass_field = driver.find_elements_by_class_name(loginView.pass_field_class)[loginView.pass_field_index]
    pass_field.clear()
    pass_field.set_value(password)

    url_field = driver.find_elements_by_class_name(loginView.url_field_class)[loginView.url_field_index]
    url_field.clear()
    url_field.set_value(server)

    table_view = driver.find_elements_by_class_name(loginView.table_view_class)[loginView.table_view_index]
    table_view.click()
    sleep(3)

    if ssl == True:
        ok_button_alert_view =  driver.find_element_by_xpath(loginView.ok_button_alert_view_xpath)
        ok_button_alert_view.click()
        sleep(3) 
    
    if ssl == True:
        text_to_check = loginView.secure_connection_name
    else:
        text_to_check = loginView.connection_name
    time_out = 60
    sleep_time = 1
    class_to_check = loginView.connection_field_class
    index_to_check = loginView.connection_field_index
    wait_until(check_values_by_name, time_out, sleep_time, driver, class_to_check, index_to_check, text_to_check)
    self.assertEqual(driver.find_elements_by_class_name(class_to_check)[index_to_check].get_attribute("name"), text_to_check)

    login_button = driver.find_elements_by_class_name(loginView.login_button_class)[loginView.login_button_index]
    login_button.click()

def wait_until(some_method, timeout, period=0.25, *args, **kwargs):
    mustend = time.time() + timeout
    while time.time() < mustend:
        if some_method(*args, **kwargs): return True
    time.sleep(period)
    return False

def check_values_by_class_name(driver, class_name, exp_value):
    number_of_classes = len(driver.find_elements_by_class_name(class_name))
    if number_of_classes == exp_value: return True
    return False

def check_values_by_name(driver, class_name, index, exp_name):
    if driver.find_elements_by_class_name(class_name)[index].get_attribute("name") == exp_name: return True
    return False

def assert_is_in_files_view(self):
    sleep(1)

    class_to_check = filesView.tabBar_class
    time_out = 20
    sleep_time = 1
    expected_class_found = 1
    wait_until(check_values_by_class_name, time_out, sleep_time, self.driver, class_to_check, expected_class_found)

    self.assertTrue(check_values_by_class_name(self.driver, class_to_check, expected_class_found))

def assert_is_not_in_files_view(self):
    sleep(1)

    class_to_check = filesView.tabBar_class
    time_out = 20
    sleep_time = 1
    expected_class_found = 0
    wait_until(check_values_by_class_name, time_out, sleep_time, self.driver, class_to_check, expected_class_found)

    self.assertTrue(check_values_by_class_name(self.driver, class_to_check, expected_class_found))

