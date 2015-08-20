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


    def test_create_folder_ok(self):
        server_url = const.K_URL_1
        user = const.K_USER_1
        password = const.K_PASSWORD_1
        ssl = const.K_SELF_SIGNED_1

        actions.doFirstLoginWith(self,server_url,user,password,ssl)
        
        #import ipdb; ipdb.set_trace()