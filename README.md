# Mood of the News via Nexmo Messages API and IBM Watson

This is a demo app of the Nexmo Messages API integrated with IBM Watson Natural Language Analyzer API and News API running on Ruby on Rails. The application responds to the sender of a WhatsApp message with the sentiment and tone of the daily headlines requested by topic. 

## Requirements

* A [Nexmo account](https://dashboard.nexmo.com/sign-up)
* A [IBM Watson account](https://www.ibm.com/watson/developer)
* A [News API account](https://newsapi.org/)
* Ruby on Rails
* [ngrok](https://ngrok.io)

## Installation

* Clone this repository
* Provision a Nexmo WhatsApp number (More info can be found [here](https://developer.nexmo.com/messages/concepts/whatsapp).)
* Create a Nexmo Messages and Dispatch application from the Nexmo dashboard
* Follow the IBM Watson instructions to create a new IBM Watson Natural Language application on their dashboard
* Sign up for a News API account
* Link your WhatsApp number to your application in the Nexmo dashboard
* Move `./env.sample` to `./env`
* Define your Nexmo, News API and IBM Watson credentials in the `/.env` file
* Start up the Rails server and ngrok

## Usage

Send a WhatsApp message with the news topic you want analyzed to your WhatsApp provisioned number. For example, send the topic "weather" to the number. You will receive a response with the overall sentiment and tone for the topic you messaged.

## License

This application is under the [MIT License](LICENSE)