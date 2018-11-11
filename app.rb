#require "./app"
# app.rb

require 'sinatra'
require "sinatra/reloader" if development?
require 'twilio-ruby'
require 'httparty'
# require 'giphy', '~> 3.0'

require 'net/http'
require 'json'

require 'did_you_mean'  if development?
require 'better_errors'  if development?

require 'cocktail_library'
require 'open-uri'
# require_relative './cocktail_library/version'
require_relative './cocktail_library/cli'
# require_relative './cocktail_library/cocktail_db'
# require_relative './cocktail_library/drink.rb'

#!/usr/bin/env ruby

require_relative "../lib/cocktail_library"

CocktailLibrary::CLI.new.run


configure :development do
  require 'dotenv'
  Dotenv.load
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

class CocktailLibrary::CLI

  def initialize
    @bases = CocktailLibrary::BASES
    @cocktail_db = CocktailLibrary::CocktailDB.new
  end

  def run
    base_selection
    drinks_available
    drink_directions
  end

  module CocktailLibrary
    VERSION = "0.1.5"
    # BASES = ["Whiskey", "Bourbon", "Scotch", "Applejack", "Cognac", "Rum", "Gin", "Tequila", "Brandy", "Apricot Brandy", "Apple Brandy", "Dark Rum"].sort!
  end

# client = Twitter::REST::Client.new do |config|
#   config.consumer_key        = "YOUR_CONSUMER_KEY"
#   config.consumer_secret     = "YOUR_CONSUMER_SECRET"
#   config.access_token        = "YOUR_ACCESS_TOKEN"
#   config.access_token_secret = "YOUR_ACCESS_SECRET"
# end

#URL:https://git.heroku.com/young-waters-11325.git
#Twilio || Project name: Marshmellowbot
#       || Account SID:ACfbb3da1cde7cfeab66f1e9645809e392
#       || Phone Number: +14122319281

enable :sessions

greetings = ["Welcome!", "Hey!", "Nice to see you."]
greetings_AM = ["Good morning", "Morning", "Good morrow"]
greetings_PM = ["Good evening", "Good night", "Sleep tight"]

get '/' do
  redirect "/about"
end


get '/about' do
  time = Time.now
  session["visits"] ||= 0  #create visit sessions variable
  session["visits"] += 1 # increments by 1

  if time.hour < 12
    greetings_AM.sample + ". A little about me. My app provides you with great event alternatives in town so that you don't get FOMO. You have visited " + session["visits"] + " times as of " + time.strftime("%Y-%m-%d %H:%M:%S")
  else
    greetings_PM.sample + ". A little about me. My app provides you with great event alternatives in town so that you don't get FOMO. You have visited " + session[:visits].to_s + "times as of " + time.strftime("%Y-%m-%d %H:%M:%S")
  end
end

get '/signup/:first_name/:number' do
  username = params[:first_name]
  usernum = params[:number]
  "Your username is " + username + "! Your number is " + usernum + "!"
end

secretcode = "chipmunk"

get "/signup/:code" do
  if params[:code] == secretcode
    erb :signup
  else
    return 403
  end
end

post "/signup" do

  if params[:code] == secretcode
      if params[:first_name] != "" && params[:number] != ""
        "Hey!" +params[:first_name] +"you will receive a message on"+params[:number]+"soon from Marshmellow Bot!"
      else
        "Please fill the required fields."
      end
  else
    return 403
  end

  get "/sms/incoming" do
    session["counter"] ||= 1
    body = params[:Body] || ""
    sender = params[:From] || ""

    if session["counter"] == 1
      client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
    #include a message here
    message = "Hi " + params[:first_name] + ", this is Marshmellow and I won't let you get mellow! I can respond to WHO, WHAT, WHERE, WHEN and WHY, or get straight to business. If you wanna go out, type FOMO for cool event suggestions. If you wanna get creative in making cocktails at home, type DARE! If you're stuck, type HELP."

      # message = "Thanks for your first message. I'm Marshmellow, but I won't make you mellow. Promise. Instead, I have some great plans for you!"
      # # "From #{sender} saying #{body}"
      # media = "https://media.giphy.com/media/13ZHjidRzoi7n2/giphy.gif"
    else
      message = determine_response body
      media = nil
    end

#   client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
# #include a message here
# message = "Hi " + params[:first_name] + ", welcome to Marshmellow MeBot! I can respond to who, what, where, when and why. Or if you wanna get to business. If you're stuck, type help."

#this will send a message from any endpoint
client.api.account.messages.create(
from: ENV["TWILIO_FROM"],
to: params[:number],
body: message
)
end

  # Build a twilio response object
  twiml = Twilio::TwiML::MessagingResponse.new do |r|
    r.message do |m|

      # add the text of the response
      m.body( message )

      # add media if it is defined
      unless media.nil?
        m.media( media )
      end
    end
  end

  # increment the session counter
  session["counter"] += 1

  # send a response to twilio
  content_type 'text/xml'
  twiml.to_s

end

get "/test/conversation/?:from?/?:body?" do
  if params[:body].nil? || params[:from].nil?
    return "No Message or Sender. Please make sure you're talking to me :)"
  end

# get '/test/conversation' do
#  403
#  end



error 403 do
  "Access Forbidden"
end

error 404 do
  "Can't find that. Let's try again! Make sure you filled in the information I need."
end

get "/test/ticketmaster" do

  ticketmaster_url = "https://app.ticketmaster.com/discovery/v2/events.json?preferredCountry=us&radius=100&unit=miles&city=Seattle&apikey=iBBPldGGNG4E7bUFw79GZwPc0goLo1nf"
  response = HTTParty.get( ticketmaster_url )


  #JSON.parse( )
  response["page"].to_json

event = response["_embedded"]["events"].sample
"When the calendar hits #{event["dates"]["start"]["localDate"]}, hit the road and go to #{event["name"]}! To find more details about the event, visit #{event["url"]}. Have absolute fun!"

resp_str = ""
  order = 0
  for event in response["_embedded"]["events"]
    order = order + 1
    resp_str += "#{order.to_s}. [#{event["name"]}]. Address: #{event["_embedded"]["venues"][0]["address"]["line1"]}. Time: [#{event["dates"]["start"]["localDate"]}, #{event["dates"]["start"]["localTime"]}] . <br/>"
  end

  resp_str
  # response["page"]["number"].to_json
end

case body
when "fomo"
  return event
end


def events_of_pittsburgh

  ticketmaster_url = "https://app.ticketmaster.com/discovery/v2/events.json?preferredCountry=us&radius=10&unit=miles&city=Pittsburgh&apikey=iBBPldGGNG4E7bUFw79GZwPc0goLo1nf"
  response = HTTParty.get( ticketmaster_url )


  #JSON.parse( )
  response["page"].to_json

  # event = response["_embedded"]["events"].sample
  # resp_str = ""
  # resp_str += "Hey check this event out: #{event["name"]}! Wanna go? It's @ " + "[Address] #{event["_embedded"]["venues"][0]["address"]["line1"]}"
  # order = 0
  # for event in response["_embedded"]["events"]
  #   order = order + 1
  #   resp_str += "#{order.to_s}. [#{event["name"]}]. Time: [#{event["dates"]["start"]["localDate"]}, #{event["dates"]["start"]["localTime"]}] . <br/>"
  # end
  return resp_str

end

case body
when "fomo"
  return events_of_pittsburgh
end


case body
when "dare"
  return "Get your creative juices flowing now! Which alcohol do you have in hand? Type the number from our menu" + DOC
else "I don't understand what you mean.If you dare to have a secret cocktail recipe, type DARE."
end

# if age < 21
			# uri = URI ("https://www.thecocktaildb.com/api/json/v1/1/filter.php?a=Non_Alcoholic")
			# response = Net::HTTP.get(uri)
			# drink_dicionary = JSON.parse(response)
			# drink_array = drink_dicionary["drinks"]
			# drink = drink_array.sample
			# message = "I'm afraid I can't recommend you an alcohol. I know it's a shame :( But of course I have great mocktails too! How about this: " + drink["strDrink"]
			# media = drink["strDrinkThumb"]

def base_selection
    @bases.each_with_index do |base, index|
      puts "#{index + 1}. #{base}"
    end

    puts ""
    puts "Please enter the number of the base alcohol you'd like to use, or type HELP to get my point. Type EXIT to quit."

    #this is all escapes for exit
    @base_choice = gets.chomp.downcase
    if @base_choice == "exit"
      puts ""

      puts "You seem like you don't wanna have fun today. BYE."
      exit
    else
         #this is defining the search object
         @base_type = @bases[@base_choice.to_i-1].downcase
       end
     end

     def drinks_available
         #this calls the search
         @drinks_list = @cocktail_db.search_by_base(@base_type)

         #escape for empty return
         if @drinks_list == nil
           puts "I'm sorry, we have no idea how to make drinks with #{@base_type.gsub(/\w+/) {|word| word.capitalize}}."
           puts "Here is grapefruit juice for you to get your bitters on."
           exit(0)
         else
           puts "Here are the drinks you can make with #{@base_type.gsub(/\w+/) {|word| word.capitalize}}:"

           puts @drinks_list
         end
       end

       def drink_directions
   puts ""
   puts "Which of these do you *dare* to make?"
   puts ""
   puts "Com'on enter the drink name, or type exit if you want to quit and have a boring night... OR you can also try searching for events in town, just type FOMO!"
   puts ""

   @search_list = @drinks_list.map {|el| el.downcase}

   drink_selection = gets.chomp.downcase
   #escape if not interested
   if drink_selection == "exit"
     puts ""
     puts "Sorry we couldn't find something you were interested in, but always be brave to make up your own creative recipe. Cheers!"
     exit

     #escape if invalid entry
        elsif !@search_list.include?(drink_selection)
          puts ""
          puts "Hmm, not sure how to make that one... Sorry about that!"
          puts ""
          drink_directions

        else
          #take drink selection and push it into the API
          drink = @cocktail_db.drink_components(drink_selection)

          puts "One second, let me grab your drink for you!"
          sleep(1)

          puts ""
          puts "Ok, so here's the secret recipe of #{drink.name.gsub(/\w+/) {|word| word.capitalize}}:  " + "Cheers!"

          drink.ingredients.each_with_index do |ing, idx|
            puts "#{drink.measurements[idx]}: #{ing}"
          end

          puts "#{drink.instructions}"
      puts ""
      puts "Hope you enjoy it!"
      puts "Wait, you want a new one? HORRAY! Just text DARE and have fun!"
    end
  end
end




 # determine_response params[:body]

def determine_response body
  body = body.downcase.strip
  jokes = IO.readlines("jokes.txt")
  facts = IO.readlines("facts.txt")
  crack = ["lol", "lolol", "haha", "jaja", "hohoyt", "FUNNY RIGHT!", "XD"]
  what_commands = ["what", "functions", "features", "actions", "purpose", "what can you do?", "tell me about you", "tell me your features", "do you have any cool functions?"]

  # return "In Body"
  case body
  when "hi","hello","hey","yo","wazzup","sup"
    return "Hello! I'm Marshmellow. I won't let you get FOMO!"
  when "who"
    return "Hi there! This is a MeBot and my name is Marshmellow. To meet my creator, Zeynep, and learn some facts about her, say fact!"
  when "what", "help", "help me"
    "I am a bot that can recommend you events in town if you wanna go out or suggest great cocktails with secret recipes if you wanna chill at home or have fun with friends! You can also ask me basic facts about my developer."
  when "where"
    "My developer and I are based in Pittsburgh. So come say hi!"
  when "when"
    "Marshmellow was born in Fall 2018"
  when "why"
    "Marshmellow was made for a class project in Programming for Online Prototypes course"
  when "joke"
    return jokes.sample + crack.sample
  when "haha", "lol", "jaja"
    return ["funny right?", "i know i'm funny", "Wanna hear another joke? Just say: joke"].sample
  when "fact", "facts"
    return facts.sample
  else
    "I don't understand what you mean. You can say: hi, who, what, where, when, why."
  end
end
end




# get "/test/giphy-sms/:search" do
#
# end

# if client.search = body
#   client.search("to:"body"", result_type: "recent").take(3).each do |tweet|
#   puts tweet.text
# end
