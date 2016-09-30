require File.expand_path('../config/environment', __FILE__)

use Rack::Cors do
	allow do
		origins '*'
		resource '*', headers: :any, methods: :get
	end
end

Bot.log=Bot::Log.new()
if DATABASE then
	Bot.db=Bot::Db.new()
end
Bot.bots={}
if TELEGRAM then
	Giskard::TelegramBot.client=Telegram::Bot::Client.new(TG_TOKEN)
	Bot.bots[TELEGRAM] = Giskard::TelegramBot
end
if FBMESSENGER then
	Giskard::FBMessengerBot.init()
	Bot.bots[FBMESSENGER] = Giskard::FBMessengerBot
end


Bot::Navigation.load_addons()
Bot.nav=Bot::Navigation.new()

run Rack::Cascade.new Bot.bots.values
