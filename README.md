## SupportBee App Platform

### Introduction

SupportBee Apps are the easiest, yet powerful way of extending/customizing SupportBee helpdesk. This platform exposes the API in a easily consumable way. The Apps are hosted on SupportBee servers.

If you are new to SupportBee, please have a look at how it works [here](https://supportbee.com)

### How does the App Platform Work?

An **App** is deeply integrated with SupportBee helpdesk. It can receive **Events** from SupportBee. It can also define **Actions**.  

_Events_ are triggered by SupportBee during various times of the lifecycle of a ticket. Currently the platform supports the following _Events_:
* Ticket Created
* Agent Reply Created
* Customer Reply Created
* Comment Created  

An App can consume one, many or all events. For example an App can send an SMS to a cell when the event "Ticket Created" is triggered.

_Actions_ are triggered by the user of SupportBee helpdesk from the User Interface. Currently the platform supports a single action called _Button_. If an App defines a Button action, a UI component is rendered for Ticket Listings in the SupportBee UI as shown below

![The Button](http://i.imgur.com/1KURN.png)

We will go more into this later.

### Writing an App

Checkout the App platform from github  
``git clone git://github.com/SupportBee/SupportBee-Apps.git``

Create a new branch with app\_name as its name  
``git branch campfire``

Bundle install and run the server locally using shotgun  
``bundle install``  
``shotgun``

Unfortunately, server requires a restart every time you change the app.

An App resides in the ``/apps`` folder of the App Platform. Each app has the following structure:

```
dummy
|--assets
|  |--views
|     |
|
|--dummy.rb
|--config.yml
```

#### config.yml
Each app has a ``config.yml`` where all the configurations of the app are defined. 

```
name: Dummy
slug: dummy
access: public
description: This is to test and a boilerplate app.
developer: 
  name: SupportBee
  email: SupportBee
  twitter: @supportbee
  github: SupportBee
action:
  button:
    screens: 
    - all
    - unassigned
    listing: 
    - all
    label: Send To Dummy
```

The ``slug`` should be unique across the platform.


#### {slug}.rb
The app logic is defined in this file. The whole app can be defined in this single file or can be spread across multiple files which are required here. The basic structure is as follows:

```
module Dummy
  module EventHandler
    def ticket_created; end
    def ticket_updated; end

    def reply_created; end
    def reply_updated; end

    def all_events; end
  end
end

module Dummy
  module ActionHandler
    def action_button
     # Handle Action here
    end

    def all_actions
    end
  end
end

module Dummy
  class Base < SupportBeeApp::Base
    string :name, :required => true
    password :key, :required => true, :label => 'Token'
    boolean :active, :default => true
  end
end
```

#### Define Settings
An app can specify the settings required by it in the ``Base`` class. These settings are accepted when the app is added to a SupportBee helpdesk. 

```
module Dummy
  class Base < SupportBeeApp::Base
    string :name, :required => true
    password :key, :required => true, :label => 'Token'
    boolean :active, :default => true
  end
end
```

An app can define a ``string``, ``password`` or a ``boolean`` type of setting. Each setting accepts a ``name`` of the settings and a set of options

* :label; if not defined, the name is humanized and rendered as the label
* :required
* :default

![The Setting](http://i.imgur.com/B1Re6.png)

#### Consume Events
An App can consume events by defining methods in ``EventHandler`` module.

```
module Dummy
  module EventHandler
    def ticket_created; end
    def ticket_updated; end

    def reply_created; end
    def reply_updated; end

    def all_events; end
  end
end
```

The event ``ticket.created`` triggers the method ``ticket_created`` and so on. The method ``all_events`` if defined is triggered for all events.

All the methods have access to the following information:
* **auth**: This is required to get SupportBee API access for the helpdesk which triggered the App. 
* **settings**: This contains the values of the settings defined by the app for the helpdesk which triggered the App.
* **payload**: This contains the event/action relavent data. This changes depending on the type of event or action.

Here is an example of a Campfire App posting to campfire on ticket creation.

```
def ticket_created
  campfire = Tinder::Campfire.new settings.subdomain, :token => settings.token
  room = campfire.find_room_by_name(settings.room)
  room.speak "New Ticket: #{payload.ticket.subject}"
end
```

#### Respond To Actions
An App can respond to actions by defining methods in ``ActionHandler``. Currently only one action is allowed; _button_.

```
module ActionHandler
  def button
    # Handle Action here
    [200, "Success"]
  end

  def all_actions
  end
end
```

**Button Action**

For a button action to work; you need to configure it in ``config.yml``

```
action:
  button:
    screens:
    - all
    - unassigned
    label: Send To Dummy
```

This renders a ``Send To Dummy`` action in the SupportBee UI for ``Unassigned`` and ``All``. When this action is triggered in the UI the method ``button`` is triggered.All actions must return a status and a optional message.  
``[200, "Successfully sent to Dummy"]``

All action methods have access to the same information as events. In addition to these a list of ticket ids selected in the listing at the time of the trigger is also provided. A button action can also define an overlay which can be used to accept more information. [Handlebars](http://handlebarsjs.com/) templating language is used to specify the overlay. The template is defined in ``APP_ROOT/assets/views/button/overlay.hbs``. When the button action is triggered this overlay will receive the list of ticket ids selected. A boilerplate of the handlebars code is as follows:

```
{{#ifTicketsCountZero tickets}}
  Do Something
{{/ifTicketsCountZero}}

{{#ifTicketsCountOne tickets}}
  Iterate over one ticket
  {{#each tickets}}
    {{subject}}
  {{/each}}
{{/ifTicketsCountZero}}

{{#ifTicketsCountZero tickets}}
  Iterate over many tickets
  {{#each tickets}}
    {{subject}}
  {{/each}}
{{/ifTicketsCountZero}}
```

### Testing/Development Console
We have created a simple console to easily trigger your Apps with sample payloads. Right now it only supports _Events_. Soon you will be able to trigger actions also. To access the console of your app go to ``/{app_slug}/console`` when running the platform locally.

![The Console](http://i.imgur.com/35VpD.png)

### More Docs to come:
#### SupportBee Objects
#### Event and Action Payloads
#### List of Apps to be developed
