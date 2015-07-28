# Atomated tests for iOS OC App

Suite of tests and needed utilities to be runned for testing the iOS OC App

It uses python as main language and selenium webdriver.


#Prepare environment
```
Install Node from [here][node]
Install python [here][python]
Install pip: sudo easy_install pip
Install nosetests: pip install nose
Download Appium UI client [here][appium] 
```


With [Homebrew][homebrew] do:
```
install node
install python
install pip
pip install nose

```
[node]: https://nodejs.org/
[python]: https://www.python.org/downloads/
[appium]: http://appium.io/
[homebrew]: http://brew.sh/


Now we can start:
```
virtualenv selenium
source selenium/bin/activate
pip install -r requirements.txt
```


In config file 'config.ini' add tests that we want to run with nose.

#Run tests

with appium activated do:
python nameTest.py
or with nose
nosetest config.ini


