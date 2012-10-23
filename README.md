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

![The Button]()

We will go more into this later.

### Parts of an App

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


#### _slug_.rb
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
