# Automated tests for iOS OC App

Suite of tests and needed utilities to be runned for testing the iOS OC App

It uses python as main language and selenium webdriver with appium.


#Prepare environment

We need to install:

* [Node][node]
* [Python][python]
* [Appium UI client][appium] 

###With [Homebrew][homebrew] do:
We need to install node without sudo to run appium.

Check if you have node installed:
```
npm --version
```

If you already have node installed with sudo remove it with following steps:
```
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf ~/.npm
brew uninstall node
```

Install node with the following steps:
```
brew install node --without-npm
echo prefix=~/.node >> ~/.npmrc
curl -L https://www.npmjs.com/install.sh | sh
export PATH="$HOME/.node/bin:$PATH”
```
Install appium
```
npm install -g appium
```
Install python
```
brew install python
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
pip install requests
pip install selenium
```

Install ipdb for debug
```
pip install ipdb
```
Use ipdb to create break points:
```
#import ipdb;ipdbs.set_trace()
```

#Config your constants
* In *constants.py* change the constants you need with your personal configuration.
* Modified *K_APP_FILE_NAME* with the path of your *.app*.
* Open Appium. From Appium IOS settings choose your build(.app) of the iPhone-Simulator from finder.
* Take into account that the device should be in English.

#Run tests
In config file 'config.ini' add tests that we want to run with nose.

* Launch appium from Appium UI or with command line ```appium &```.

* Launch a single test file:
```
python nameTest.py
```
or launch several test files with nose:
```
nosetests -c config.ini
```
