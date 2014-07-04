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


## Happy Hacking! Bee Awesome!
