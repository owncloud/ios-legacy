# Automated tests for iOS OC App

Suite of tests and needed utilities to be runned for testing the iOS OC App

It uses python as main language and selenium webdriver with appium.


#Prepare environment

We need to install:

* [Node][node]
* [Python][python]
* [Appium UI client][appium] 

Or with [Homebrew][homebrew] do:
```
brew install node
brew install python
npm install -g appium
```

[node]: https://nodejs.org/
[python]: https://www.python.org/downloads/
[appium]: http://appium.io/
[homebrew]: http://brew.sh/

Install pip and packages:
```
sudo easy_install pip
pip install nose
pip install Appium-Python-Client
```

#Config your constants
In *constants.py* change the constants you need with your personal configuration.
Modified *K_APP_FILE_NAME* with the path of your *.app*.
Open Appium. From Appium IOS settings choose your build(.app) of the iPhone-Simulator from finder.

#Run tests
In config file 'config.ini' add tests that we want to run with nose.

* Launch appium from Appium UI or with command line 'appium &'.

* Launch test:
```
python nameTest.py
```
or launch test with nose:
```
nosetests -c config.ini
```
