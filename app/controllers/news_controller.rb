require 'news-api'
require 'ibm_watson/natural_language_understanding_v1'
require 'json'
require 'byebug'
class NewsController < ApplicationController
  skip_before_action :verify_authenticity_token
  include ActionView::Helpers::NumberHelper

  def inbound
    # assign variables
    topic = params[:message][:content][:text]
    recipient_number = params[:from][:number]
    
    # get headlines and process them for sentiment and tone
    analyze_headlines(topic, recipient_number)
  end

  def status
    puts params
  end

  private

  def generate_jwt_token
    claims = {
      application_id: ENV['NEXMO_APPLICATION_ID']
    }
    private_key = File.read('./private.key')
    token = Nexmo::JWT.generate(claims, private_key)
    token
  end

  def get_news_headlines(topic)
    news = News.new(ENV['news_api_key'])
    headlines = news.get_everything(q: "#{topic}", from: "#{Date.today}", sortBy: "popularity")
    headline_string = ''
    headlines.each do |headline|
     headline_string << " #{headline.title}"
    end
    headline_string
  end

  def analyze_headlines(topic, recipient_number)
    natural_language_understanding = IBMWatson::NaturalLanguageUnderstandingV1.new(
      iam_apikey: "#{ENV['watson_api_key']}",
      version: "2018-11-16"
    )
    natural_language_understanding.url = 'https://gateway-lon.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2018-11-16'
    response = natural_language_understanding.analyze(
      text: get_news_headlines(topic),
      features: {
        "sentiment" => {},
        "emotion" => { "document" => true }
      }
    ).result

    # send WhatsApp message
    send_whatsapp_msg(response, topic, recipient_number)
  end

  def send_whatsapp_msg(news, topic, recipient_number) 
    require 'net/https'
    require 'json'

    # define values
    sentiment = news['sentiment']['document']['label']
    sadness = number_to_percentage(news['emotion']['document']['emotion']['sadness'].to_f, precision: 0) 
    joy = number_to_percentage(news['emotion']['document']['emotion']['joy'].to_f, precision: 0)
    fear = number_to_percentage(news['emotion']['document']['emotion']['fear'].to_f, precision: 0)
    disgust = number_to_percentage(news['emotion']['document']['emotion']['disgust'].to_f, precision: 0)
    anger = number_to_percentage(news['emotion']['document']['emotion']['anger'].to_f, precision: 0)

    begin
        uri = URI('https://api.nexmo.com/v0.1/messages')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, {
          'Content-Type' => 'application/json',  
          'Authorization' => "Bearer #{generate_jwt_token}"
        })
        req.body = {
          'from' => {'type' => 'whatsapp', 'number' => ENV['NEXMO_WHATSAPP_NUMBER']},
          'to' => {'type' => 'whatsapp', 'number' => recipient_number},
          'message' => {
            'content' => {
              'type' => 'text',
              'text' => <<~HEREDOC
              Overall news sentiment on #{topic} is #{sentiment} with #{sadness} of sadness,
              #{joy} of joy, #{fear} of fear, #{disgust} of disgust and #{anger} of anger
              in emotional content.
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
