
import os
from datetime import datetime

#--Generic Variables for use through Appium connection
K_APP_FILE_NAME = '/Users/Gonzalo/Desktop/owncloud.ipa'
K_APPIUM_VER = '1.4.1'
K_APP_PLATFORM_NAME = 'iOS'
K_APP_PLATFORM_VER = '8.2'
K_DEVICE_NAME = 'iPhone'

#--Webdriver property 
K_WD_EXPLICITY_WAIT = 20
K_WD_REMOTE_URL = 'http://0.0.0.0:4723/wd/hub'

#--Result Files
K_RST_FILE = '/Result/test.txt'
K_RST_FILE_PATH = os.path.dirname(os.path.realpath(__file__)) + K_RST_FILE
K_RST_HTML_FILE = '/result.html'
K_RST_HTML_FILE_PATH = os.path.dirname(os.path.realpath(__file__)) + K_RST_HTML_FILE
K_RST_PDF_FILE = 'Report'

#--Execption/Fails 
K_FILE_NOT_FOUND = 'File not found for given path %s'

class utility_functions():

    #--Common utils for Apending string in test.txt file.
    def write_comment_in_file(self,text):
        f = open(K_RST_FILE_PATH, "a")
        f.write('Time: %s ' % datetime.now())
        f.write(text)
        f.close()
        return True