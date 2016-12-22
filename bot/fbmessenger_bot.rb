# encoding: utf-8

=begin
   Copyright 2016 Telegraph-ai

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
=end

require_relative 'navigation.rb'

module Giskard
	class FBMessengerBot < Grape::API
		prefix FB_WEBHOOK_PREFIX.to_sym
		format :json

		def self.send(payload,type="messages",file_url=nil)
			if file_url.nil? then
				begin
					RestClient.post "https://graph.facebook.com/v2.8/me/#{type}?access_token=#{FB_PAGEACCTOKEN}", payload.to_json, :content_type => :json
				rescue => e
					Bot.log.info e.response
				end
			end
		end

		def self.init()
			payload={ "setting_type"=>"greeting", "greeting"=>{ "text"=>"Hello, ca fiouze ?" }}
			Giskard::FBMessengerBot.send(payload,"thread_settings")
		end


		helpers do
			def authorized # Used for API calls and to verify webhook
				headers['Secret-Key']==FB_SECRET
			end
		end

		# challenge for creating a webhook
		get '/fbmessenger' do
			Bot.log.info "#{__method__} challenge"
			if params['hub.verify_token']==FB_SECRET then
				return params['hub.challenge'].to_i
			else
				return "nope"
			end
		end

		# we receive a new message
		post '/fbmessenger' do
			entries     = params['entry']
			entries.each do |entry|
				entry.messaging.each do |messaging|
					Bot.log.debug messaging
					id_sender = messaging.sender.id
					id_receiv = messaging.recipient.id
					if not messaging.message.nil? then
						payload={"recipient"=>{"id"=>id_sender},
							"message"=>{"text"=>"Bonjour ! Je suis encore en construction ! Merci de revenir plus tard. "}}
						begin
							RestClient.post "https://graph.facebook.com/v2.8/me/#{type}?access_token=#{FB_PAGEACCTOKEN}", payload.to_json, :content_type => :json
						rescue => e
							Bot.log.info e.response
						end
					end

				end
			end
		end
	end
end
