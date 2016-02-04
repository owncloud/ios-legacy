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
import requests

webdav_entry_point = "/remote.php/webdav/"

def deleteFile(server,user,password,file):
    url = server + webdav_entry_point + file
    r = requests.delete(url, auth=(user, password), verify=False)
    print r.status_code

def isFile(server,user,password,file):
    result = False
    url = server + webdav_entry_point + file
    r = requests.head(url, auth=(user, password), verify=False)
    print r.status_code
    if r.status_code == 200:
        result = True
    return result