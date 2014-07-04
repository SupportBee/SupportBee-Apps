### Welcome

Good Evening Hackers!

Thank you for choosing to hack on SupportBee API/Platform. We hope you will have a great time building apps on top of SupportBee.

SupportBee is the easiest way to manage customer support emails. The customers of the company using SupportBee will contact them via email which are forwarded to SupportBee. These emails are converted to _tickets_. Multiple people can login to the same shared inbox where they can and reply to these tickets. The tickets can be assigned to different agents. They can be categoried using labels. The workflow is very similar to Gmail.

### API and App Platform

We have a JSON REST API. It powers our own frontend. So it can do whatever our own frontend can do. The API docs can be found here https://developers.supportbee.com/api. We care about [developer experience](https://www.youtube.com/watch?v=V3rQWpnykyY) so we built an app platform over our API. Our platform takes care of all the setup required to use an API. For example: Authentication. It lets you concentrate on the app itself. You can learn more about the platform here: https://developers.supportbee.com

For this HackNight we are opening up our staging environment. 

Until recently, some of the capabilities that the platform offer were untestable as they would need access to our core application codebase. For the first time, at this Hacknight, we are introducing a new way to test your apps as they are built. This is still in alpha, so we have deployed it on our staging server. So to test the apps you are writing please do the following:

- Go to https://reminderhawk.com . This is our staging server. 
- Sign up for a SupportBee account. 
- By default, your SupportBee account connects to a App Platform running locally on the staging server.
- Follow the instructions here: https://developers.supportbee.com/platform/overview to run the App Platform locally.
- One you have the platform running, you have to expose the platfrom the internet so our staging server can interact with it. You can achieve this using https://forwardhq.com/. On signup, follow the instruction to forward a localhost port. You will also get a URL through which your locally running app platfrom can be accessed.
- Shout out to one of us and we will enable the URL for you.
- Now your local app platform can commnicate with the staging server.


## What can you do?

### WRAPPERS

In the last hackathon, the guys from HasGeek built an awsome Python wrapper. https://github.com/sivaa/supportbee-python
If you are in the mood for refactoring, you extract a Ruby wrapper out of the App Platform code. Are you a Mobile Developer? How about an sdk for Android/IOS. We will compile all of them and make a page out of it. You will retain all the credits :)

### Widgets

Innovate on creation of ticket creation widgets. We have very simple web widget to create a ticket. How about a way to send crash reports to SupportBee from a mobile app?

### Apps
+ NLP on our push events
+ Google Calendar Integration

### Hack on the App Platform

Improve the capabilites of the platform itself! Pair program with us if you want to know how our platform works!


## Chat with us
https://scrollback.io/supportbee-community


## Goodies

We have many TShirts, Stickers to give away. Our favourite hacker gets a lunch invite to our cozy office (PS: We have an awesome cook!).

![photo 2014-07-02 10_21 2 jpg](https://cloud.githubusercontent.com/assets/1789832/3468375/21b175fa-029d-11e4-9b0d-3bcce2f56de7.jpg)

![photo 2014-07-02 10_21 3 jpg](https://cloud.githubusercontent.com/assets/1789832/3468383/35afb5c6-029d-11e4-9241-886070e6f698.jpg)

## Hacking on SupportBee's App Platform

### Installing Ruby

#### Installing Ruby on Windows

+ Download Ruby 1.9.3 from http://rubyinstaller.org/

![ruby_installer_home_page](https://cloud.githubusercontent.com/assets/1789832/3481043/5a4625b4-036a-11e4-9b2d-3be7342a2c13.png)

![ruby19_download_link](https://cloud.githubusercontent.com/assets/1789832/3481062/a1a13110-036a-11e4-8eb3-631caa1398bf.png)

+ Double click and run the ruby installer. Ignore the security warning.

![security_warning](https://cloud.githubusercontent.com/assets/1789832/3481101/2fad4732-036b-11e4-884f-32347d4d957f.png)

+ The executable is a typical Windows Installer. In the Installation Options screen, tick the options `Add Ruby executables in your PATH`, `Associate .rb and .rbw files with this Ruby installation`.

![installation_options](https://cloud.githubusercontent.com/assets/1789832/3481179/54cff572-036c-11e4-8c52-6ee03009f67d.png)

+ Ensure ruby 1.9.3 in installed by running `ruby -v`
```
ruby -v
```
in the command prompt

![installation_successful](https://cloud.githubusercontent.com/assets/1789832/3481315/3412f912-036f-11e4-982a-4edbf4c6c817.png)

### Setting up the App Platform

Extensive instructions to run the app platform are available [here](https://developers.supportbee.com/platform/overview).

For the impatient ones..

+ Clone the App Platform (https://github.com/SupportBee/SupportBee-Apps/)

```
git clone https://github.com/SupportBee/SupportBee-Apps/
```

+ Bundler is a great tool to manage gems (libraries in ruby are called gems) in ruby projects. Install bundler. 

```
gem install bundler
```

+ Install App Platform dependencies

```
bundle install
```

+ Copy the default config files

```
cp config/omniauth.platform.example.yml config/omniauth.platform.yml
```

+ Rackup! The server runs on port 9292

```
% rackup
Preparing Assets...
[2014-07-04 17:33:56] INFO  WEBrick 1.3.1
[2014-07-04 17:33:56] INFO  ruby 1.9.3 (2013-11-22) [x86_64-darwin13.0.2]
[2014-07-04 17:33:56] INFO  WEBrick::HTTPServer#start: pid=86474 port=9292
```

### Register your SupportBee

We have repurposed our staging servers for the Hacknight. Head out to http://reminderhawk.com/ and create your SupportBee.

### Talk to us

We're around. We are looking forward to talk about our API, pair program with you and get you started with a demo app using our app platform.  

## Happy Hacking! Bee Awesome!
