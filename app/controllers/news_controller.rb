require 'news-api'
require "ibm_watson/authenticators"
require 'ibm_watson/natural_language_understanding_v1'
require 'json'

class NewsController < ApplicationController
  skip_before_action :verify_authenticity_token
  include ActionView::Helpers::NumberHelper

  def inbound
    # assign variables
    topic = params[:message][:content][:text]
    recipient_number = params[:from][:number]

    # get headlines and process them for sentiment
    analyze_headlines(topic, recipient_number)

    head :no_content
  end

  def status
    puts params
    head :no_content  
  end

  private

  def generate_jwt_token
    claims = {
      application_id: ENV['VONAGE_APPLICATION_ID']
    }
    private_key = File.read('./private.key')
    token = Vonage::JWT.generate(claims, private_key)
    token
  end

  def get_news_headlines(topic)
    news = News.new(ENV['news_api_key'])
    headlines = news.get_everything(
      q: "#{topic}", from: "#{Date.today}", 
      sortBy: "popularity"
    )
    headline_string = ''
    headlines.each do |headline|
     headline_string << " #{headline.title}"
    end
    puts "HERE ARE THE HEADLINES: #{headline_string}\n\n"
    headline_string
  end

  def analyze_headlines(topic, recipient_number)
    authenticator = IBMWatson::Authenticators::IamAuthenticator.new(
      apikey: "#{ENV['watson_api_key']}"
    )

    natural_language_understanding = IBMWatson::NaturalLanguageUnderstandingV1.new(
      authenticator: authenticator,
      version: "2018-03-16"
    )

    natural_language_understanding.service_url = 'https://gateway-lon.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2018-11-16'
    response = natural_language_understanding.analyze(
      text: get_news_headlines(topic),
      language: "en",
      features: {
        "entities" => {},
        "keywords" => {},
        "sentiment" => {},
        "categories" => {explanation: true},
        "concepts" => {},
        "relations" => {},
        "semantic_roles" => {},
        "emotion" => { "document" => true }
      }
    ).result

    puts JSON.pretty_generate(response)

    # send WhatsApp message
    send_whatsapp_msg(response, topic, recipient_number)
  end

  def send_whatsapp_msg(news, topic, recipient_number) 
    require 'net/https'

    # define values
    sentiment = news['sentiment']['document']['label']
    emotions = news['emotion']['document']['emotion']
    sadness = number_to_percentage(emotions['sadness'] * 100) 
    joy = number_to_percentage(emotions['joy'] * 100)
    fear = number_to_percentage(emotions['fear'] * 100)
    disgust = number_to_percentage(emotions['disgust'] * 100)
    anger = number_to_percentage(emotions['anger'] * 100)

    begin
        uri = URI('https://api.nexmo.com/v0.1/messages')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, {
          'Content-Type' => 'application/json',  
          'Authorization' => "Bearer #{generate_jwt_token}"
        })
        req.body = {
          'from' => {'type' => 'whatsapp', 'number' => ENV['VONAGE_WHATSAPP_NUMBER']},
          'to' => {'type' => 'whatsapp', 'number' => recipient_number},
          'message' => {
            'content' => {
              'type' => 'text',
              'text' => <<~HEREDOC
              Hello there! 👋
      
              You asked for the mood of the news on the following topic: #{topic}. 
              Here you go!
      
              The overall news sentiment on #{topic} is #{sentiment} 
              with #{sadness} of sadness, #{joy} of joy, #{fear} of fear, 
              #{disgust} of disgust and #{anger} of anger in emotional tone.
      
              Thank you for using Mood of the News powered by Vonage, IBM Watson 
              and the News API!
              HEREDOC
            }
          }  
        }.to_json

        res = http.request(req)
        puts "response #{res.body}"
        puts JSON.parse(res.body)
    rescue => e
        puts "failed #{e}"
    end
  end
end
