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
      text: "Scotland's leader tells UK PM Johnson: we want an independence referendum British PM Johnson's top team meet to plot Brexit gambit DUP's Donaldson says party wants Britain to leave with a deal DUP calls for 'fresh start' in search for a sensible deal 'Cabinet from hell': Boris Johnson hires ministers who backed hanging, called feminists 'obnoxious bigots' and opposed gay marriage Boris Johnson’s Two Biggest Problems Are One and the Same Outside the Box: Germany and the U.S. need to compromise — but both are too stubborn Years and Years: un posible futuro y cómo viviremos la tecnología y los problemas de hoy dentro de 15 años UK prime minister appoints Brexit supporters to cabinet Brexit Bulletin: Radical Overhaul Netgear Inc (NTGR) Q2 2019 Earnings Call Transcript LeMaitre Vascular (LMAT) Q2 2019 Earnings Call Transcript SEI Investments Company (SEIC) Q2 2019 Earnings Call Transcript The Bank of N.T. Butterfield & Son Limited (NTB) Q2 2019 Earnings Call Transcript Hilton Worldwide Holdings (HLT) Q2 2019 Earnings Call Transcript Who is Priti Patel? Priti Patel takes charge as first British Indian home secretary Boris Johnson stellt Kabinett mit Brexit-Hardlinern vor Rising high, Sajid Javid named UK finance minister to guide Brexit economy UK PM Johnson tells ministers: we are all committed to leaving EU by October 31",
      features: {
        "sentiment" => {},
        "emotion" => { "document" => true }
      }
    ).result

    # redirect to show path
    redirect_to news_show_path(news: @response)
  end

  def show
    @news = params['news']
  end
end
