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
					RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}", payload.to_json, :content_type => :json
				rescue => e
					Bot.log.info e.response
				end
			else # image upload # FIXME file upload does not work : 400 Bad Request
				params={"recipient"=>payload['recipient'], "message"=>payload['message'], "filedata"=>File.new(file_url,'rb'),"multipart"=>true}
				begin
					RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}",params
				rescue => e
					Bot.log.info e.response
				end
			end
		end

		def self.init()
			payload={ "setting_type"=>"greeting", "greeting"=>{ "text"=>"Hello, ca fiouze ?" }}
			Giskard::FBMessengerBot.send(payload,"thread_settings")
			Giskard::FBMessengerBot.load_queries
		end

		def self.load_queries
			queries={
				"fb_select" => "SELECT * FROM #{DB_PREFIX}fb_users WHERE usr_id = $1",
				"fb_insert"  => "INSERT INTO #{DB_PREFIX}fb_users (id, usr_id, profile_pic, locale, timezone, gender) VALUES (?, ?,?,?,?,?)"
			}
			queries.each { |k,v| Bot.db.prepare(k,v) }
		end

		def self.add(user)
			if Bot.db.is_connected? then
				params = [
 					user.id,
					user.fb_id,
					user.profile_pic,
					user.gender,
					user.locale,
					user.timezone
				]
				Bot.db.query("fb_insert", params)
			end
			return user
		end

		def self.load(user)
			if Bot.db.is_connected? then
				params = [user.id]
				r = Bot.db.query("fb_select", params)
				r.each do |row|
					row = r[0]
					user.gender 	  = row['gender']
					user.profile_pic  = row['profile_pic']
					user.locale 	  = row['locale']
					user.timezone  	  = row['timezone']
					user.fb_id	      = row['id']
				end
			end
			return user
		end

		def self.create(user)
			res              = URI.parse("https://graph.facebook.com/v2.6/#{user.id}?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=#{FB_PAGEACCTOKEN}").read
			r_user           = JSON.parse(res)
			r_user           = JSON.parse(JSON.dump(r_user), object_class: OpenStruct)
			user.first_name  = r_user.first_name
			user.last_name   = r_user.last_name
			user.gender		 = r_user.gender # TODO: translate in m or w
			user.timezone	 = r_user.timezone
			user.locale		 = r_user.locale
			user.profile_pic = r_user.profile_pic
			Bot.log.debug("Nouveau participant : #{user.first_name} #{user.last_name}")
			return user
		end

		helpers do
			def authorized # Used for API calls and to verify webhook
				headers['Secret-Key']==FB_SECRET
			end

			def send_msg(id,text,kbd=nil)
				msg={"recipient"=>{"id"=>id},"message"=>{"text"=>text}}
				if not kbd.nil? then
					msg["message"]["quick_replies"]=[]
					kbd.each do |k|
						msg["message"]["quick_replies"].push({
							"content_type"=>"text",
							"title"=>k,
							"payload"=>k
						})
					end
				end
				Giskard::FBMessengerBot.send(msg)
			end

			def send_typing(id)
				Giskard::FBMessengerBot.send({"recipient"=>{"id"=>id},"sender_action"=>"typing_on"})
			end

			def send_image(id,img_url)
				payload={"recipient"=>{"id"=>id},"message"=>{"attachment"=>{"type"=>"image","payload"=>{}}}}
				if not img_url.match(/http/).nil? then
					payload["message"]["attachment"]["payload"]={"url"=>img_url}
					Giskard::FBMessengerBot.send(payload)
				else
					Giskard::FBMessengerBot.send(payload,"messages",img_url)
				end
			end

			def send_attachment(id,attachment)
				Bot.log.info "#{__method__}"
				payload={"recipient"=>{"id"=>id},
						"message"=>{"attachment"=>attachment}
					}
				Bot.log.info payload.to_json
				Giskard::FBMessengerBot.send(payload)
			end

			def send_elements(id,elmts)
				Bot.log.info "#{__method__}"
				payload={"recipient"=>{"id"=>id},
						"message"=>{"attachment"=>{
											"type"=>"template",
											"payload"=>{
													"template_type" =>"generic",
													"elements" 		=> elmts
													}
											}
									}
					}
				Giskard::FBMessengerBot.send(payload)
			end

			def process_msg(id,msg,options)
				lines=msg.split("\n")
				buffer=""
				max=lines.length
				idx=0
				image=false
				kbd=nil
				lines.each do |l|
					next if l.empty?
					idx+=1
					image=(l.start_with?("image:") && (['.jpg','.png','.gif','.jpeg'].include? File.extname(l)))
					if image && !buffer.empty? then # flush buffer before sending image
						writing_time=buffer.length/TYPINGSPEED
						send_typing(id)
						sleep(writing_time)
						send_msg(id,buffer)
						buffer=""
					end
					if image then # sending image
						send_typing(id)
						send_image(id,l.split(":",2)[1])
					else # sending 1 msg for every line
						writing_time=l.length/TYPINGSPEED
						writing_time=l.length/TYPINGSPEED_SLOW if max>1
						send_typing(id)
						sleep(writing_time)
						if l.start_with?("no_preview:") then
							l=l.split(':',2)[1]
						end
						if (idx==max)
							kbd=options[:kbd]
						end
						send_msg(id,l,kbd)
					end
				end
			end
		end

		# challenge for creating a webhook
		get '/fbmessenger' do
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
					puts messaging
					id_sender = messaging.sender.id
					id_receiv = messaging.recipient.id
					timestamp = messaging.time
					id 		  = timestamp
					if not messaging.message.nil? then
						text      = messaging.message.text
					elsif not messaging.postback.nil? then
						text      = messaging.postback.payload
					end
					user     = Bot::User.new()
					user.id  = id_sender
					user.bot = FB_BOT_NAME

					if not text.nil? then
						# read message
						msg           = Giskard::Message.new(id, text, id, FB_BOT_NAME)
						msg.timestamp = timestamp
						screen        = Bot.nav.get(msg, user)

						# send answer
						process_msg(user.id,screen[:text],screen) unless screen[:text].nil?
						if not screen[:elements].nil?
							send_elements(user.id, screen[:elements])
						end
						# TODO send WebView
						Bot.log.info screen
						if not screen[:attachment].nil?
							send_attachment(user.id, screen[:attachment])
						end
					end
				end
			end
		end
	end
end
