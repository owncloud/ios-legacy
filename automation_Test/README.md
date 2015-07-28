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

#Run tests
In config file 'config.ini' add tests that we want to run with nose.

with appium activated do:
```
python nameTest.py
```
or with nose:
```
nosetests -c config.ini
```
