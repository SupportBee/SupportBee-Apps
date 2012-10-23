### SupportBee App Platform

#### Introduction

SupportBee Apps are the easiest, yet powerful way of extending/customizing SupportBee helpdesk. This platform exposes the API in a easily consumable way. The Apps are hosted on SupportBee servers.

If you are new to SupportBee, please have a look at how it works [here](https://supportbee.com)

#### How does the App Platform Work?

An **App** is deeply integrated with SupportBee helpdesk. It can receive **Events** from SupportBee. It can also define **Actions**.  

_Events_ are triggered by SupportBee during various times of the lifecycle of a ticket. Currently the platform supports the following _Events_

1) Ticket Created
2) Agent Reply Created
3) Customer Reply Created
4) Comment Created

An App can consume one, many or all events. For example an App can send an SMS to a cell when the event "Ticket Created" is triggered

__Actions__ are triggered by the user of SupportBee helpdesk from the User Interface. Currently the platform supports a single action called _Button_.

If an App defines a Button action, a UI component is rendered for Ticket Listings in the SupportBee UI as shown below

![The Button]()

We will go more into this later.


