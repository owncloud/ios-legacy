import time
import os
from time import sleep
import constant as const
from appium import webdriver

def getWebDriver():
    desired_caps = {}
    desired_caps['appium-version'] = const.K_APPIUM_VER
    desired_caps['platformName'] = const.K_APP_PLATFORM_NAME
    desired_caps['platformVersion'] = const.K_APP_PLATFORM_VER
    desired_caps['deviceName'] = const.K_DEVICE_NAME
    return webdriver.Remote('http://0.0.0.0:4723/wd/hub', desired_caps)

def doLoginWith(driver,server,user,password, ssl):
    user_field = driver.find_elements_by_class_name('UIATextField')[1]
    user_field.clear()
    user_field.set_value(user)

    pass_field = driver.find_elements_by_class_name('UIASecureTextField')[0]
    pass_field.clear()
    pass_field.set_value(password)

    url_field = driver.find_elements_by_class_name('UIATextField')[0]
    url_field.clear()
    url_field.set_value(server)

    table_view = driver.find_elements_by_class_name('UIATableView')[0]
    table_view.click()
    sleep(3)

    if ssl == True:
        ok_button_alert_view =  driver.find_element_by_xpath("//UIAApplication[1]/UIAWindow[4]/UIAAlert[1]/UIACollectionView[1]/UIACollectionCell[2]")
        ok_button_alert_view.click()
        sleep(3) 

    login_button = driver.find_elements_by_class_name('UIAStaticText')[1]
    login_button.click()
