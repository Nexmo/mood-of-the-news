require 'news-api'
require 'ibm_watson/natural_language_understanding_v1'
require 'json'
require 'byebug'
class NewsController < ApplicationController

  def index
  end

  def create
    # get the news headlines
    news = News.new(ENV['news_api_key'])
    headlines = news.get_everything(q: "#{current_user.topic}", from: "#{Date.today}", sortBy: "popularity")
    headline_string = ''
    headlines.each do |headline|
     headline_string << " #{headline.title}"
    end

    # process them for sentiment analysis
    natural_language_understanding = IBMWatson::NaturalLanguageUnderstandingV1.new(
      iam_apikey: "#{ENV['watson_api_key']}",
      version: "2018-11-16"
    )
    natural_language_understanding.url = 'https://gateway-lon.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2018-11-16'
    @response = natural_language_understanding.analyze(
      text: headline_string,
      features: {
        "sentiment" => {},
        "emotion" => { "document" => true }
      }
    ).result

    # redirect to show path
    redirect_to news_show_path(news: @response)
    messages_post_req(@response)
  end

  def show
    @news = params['news']
  end

  private

  def messages_post_req(news) 
    require 'net/https'
    require 'json'

    claims = {
      application_id: ENV['NEXMO_APPLICATION_ID'],
      nbf: 1564109791,
      iat: 1564109095,
      exp: 1595645095,
    }
    private_key = File.read('./private.key')
    token = Nexmo::JWT.generate(claims, private_key)
    begin
        uri = URI('https://api.nexmo.com/v0.1/messages')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json',  
          'Authorization' => "Bearer #{token}"})
        req.body = {
          'from' => {'type' => 'whatsapp', 'number' => ENV['NEXMO_WHATSAPP_NUMBER']},
          'to' => {'type' => 'whatsapp', 'number' => PHONE_NUMBER},
          'message' => {
            'content' => {
              'type' => 'text',
              'text' => "Overall sentiment: #{news.dig(:news,:sentiment,:document,:label)}"
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
