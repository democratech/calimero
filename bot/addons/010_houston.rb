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

$HOUSTON_TEXT_LIM = 200


module Houston
	def self.load_queries
		queries={
			"houston_select_dol_perso" => "SELECT * FROM #{DB_PREFIX}messages where usr_id=$1",
			"houston_select_dol_last" => "SELECT msg, url, first_name, date, usr_id FROM  #{DB_PREFIX}messages JOIN  #{DB_PREFIX}images ON #{DB_PREFIX}images.id = #{DB_PREFIX}messages.img_id JOIN #{DB_PREFIX}users on #{DB_PREFIX}users.id = usr_id order by #{DB_PREFIX}messages.date desc limit 3",
			"houston_select_cat" => "SELECT * FROM #{DB_PREFIX}categories limit 3",
			"houston_insert"  => "INSERT INTO #{DB_PREFIX}messages (usr_id, msg, img_id) VALUES ($1, $2, $3) returning date",
			"houston_select_img"  => "SELECT * FROM #{DB_PREFIX}images WHERE category = $1 order by random() limit 1",
			"houston_feedback" => "INSERT INTO #{DB_PREFIX}feedback (usr_id, msg, useful) VALUES ($1, $2, $3)"
		}
		queries.each { |k,v| Bot.db.prepare(k,v) }
	end


	def self.included(base)
		Bot.log.info "loading Houston add-on"
		Houston.load_queries
		messages={
			:en=>{
				:houston=>{
					:no=>"Non",
					:yes=>"Oui",
					:welcome_answer=>"/start",
					:welcome=><<-END,
Hi %{firstname} !
I am Houston. #{Bot.emoticons[:blush]}
My purpose is to write down your message for French politics.
At the end, I will offer you an image to convey on your social networks.
Let's start!
END
					:menu_answer=>"#{Bot.emoticons[:home]} Accueil",
					:menu=><<-END,
What do you want to do?
You can recover a former message, or write a new one.
Please use the following buttons to give me your choice.
END
# 					:ask_img_answer=>"Recover",
# 					:ask_img=><<-END,
# Let me recover your message...
# END
# 					:get_img=><<-END,
# Here is your message!
# END
# 					:bad_img=><<-END,
# I feel sorry that you don't like the image.  #{Bot.emoticons[:confused]}
# Let's try again.
# END
# 					:good_img=><<-END,
# Great! Please share this image on your social networks!
# END
# 					:ask_wrong=><<-END,
# Hmmm... I can't recover your former message... #{Bot.emoticons[:confused]}
# Please write a new one.
# END
# 					:ask_txt_answer=>"Write",
# 					:ask_txt=><<-END,
# According to you, what is the priority in France?
# END
# 					:end=><<-END,
# I hope you enjoyed our conversation! See you!
# END
				}
			},
			:fr=>{
				:houston=>{
					:no=>"Non",
					:yes=>"Oui",
					:welcome_answer=>"/start",
					:welcome=><<-END,
Bonjour %{firstname} !
Je suis le robot de LaPrimaire.org. #{Bot.emoticons[:blush]}
END
					:menu_answer=>"#{Bot.emoticons[:home]} Accueil",
					:menu=><<-END,
Que voulez-vous faire ?
Utilisez les boutons du menu ci-dessous pour m'indiquer ce que vous souhaitez faire.
END
					:delivery => "Et voilà !\n",
					:too_long => <<-END,
La limite de caractères est de #{$HOUSTON_TEXT_LIM}. Merci de recommencer.
END
# 					:ask_img_answer=>"Retrouver",
# 					:ask_img=><<-END,
# Je recherche votre demande...
# END
# 					:get_img=><<-END,
# Voici votre demande ! Vous convient-elle?
# END
# 					:bad_img=><<-END,
# Je suis navré que l'image ne vous plaise pas.  #{Bot.emoticons[:confused]}
# Reprenons.
# END
# 					:good_img=><<-END,
# Génial ! Je vous laisse alors partager cette image sur vos réseaux sociaux !
# END
# 					:ask_wrong=><<-END,
# Hmmm... Je ne retrouve pas votre priorité... #{Bot.emoticons[:confused]}
# Reprenons.
# END
					# :ask_txt_answer=>"Ecrire",
					:ask_theme=><<-END,
A quel thème pouvez-vous associer ce propos ?
END
					:end=><<-END,
Je vous remercie de votre temps. À bientôt !
END
					:feedback=><<-END,
Je viens d'être créée, j'ai besoin de votre ressenti pour m'améliorer. Que pensez-vous de votre expérience de conversation ?
END
					
				}
			}
		}
		screens={
			:houston=>{
				:welcome=>{
					:answer=>"houston/welcome_answer",
					:disable_web_page_preview=>true,
					:callback=>"houston/welcome"
				},
				:menu=>{
					:answer=>"houston/menu_answer",
					:callback=>"houston/welcome",
					:parse_mode=>"HTML"
				},
				:too_long=> {
					:callback=>"houston/too_long"
				},
				# :get_img=>{
				# 	:callback=>"houston/get_img",
				# 	:parse_mode=>"HTML",
				# 	:kbd=>["houston/bad_img","houston/good_img"],
				# 	:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true}
				# },
				# :bad_img=>{
				# 	:answer=>"houston/no",
				# 	:jump_to=>"houston/ask_txt"
				# },
				# :good_img=>{
				# 	:answer=>"houston/yes",
				# 	:callback=>"houston/end"
				# },
				#
				# :ask_img=>{
				# 	:answer=>"houston/ask_img_answer",
				# 	:callback=>"houston/ask_img"
				# },
				# :ask_wrong=>{
				# 	:jump_to=>"houston/menu"
				# },
				:ask_themes=>{
					:callback=>"houston/ask_themes"
				},
				:carousel=>{},
				:delivery=>{ :jump_to=>"houston/feedback"},
				:end=>{},
				:feedback=>{
					:callback=>"houston/feedback"
				}

			}
		}
		Bot.updateScreens(screens)
		Bot.updateMessages(messages)
		# Bot.addMenu({:houston=>{:menu=>{:kbd=>"houston/menu"}}})
	end

	def houston_welcome(msg,user,screen)
		Bot.log.info "#{__method__}"
		#screen=self.find_by_name("houston/carousel",self.get_locale(user))
		screen[:elements]= [
			{
				:title 		=> "Ecrivez votre doléance",
				:image_url  => "http://guhur.net/img/megaphone.png",
			},
			{
				:title 		=> "Exemple",
				:image_url  => "http://guhur.net/img/demo1.jpg",
			},
			{
				:title 		=> "Exemple",
				:image_url  => "http://guhur.net/img/demo2.jpg",
			}  ]
		# results = Bot.db.query("houston_select_dol_last")
		# results.each do |row|
		# 	output = "img/#{row['date']}_#{row['usr_id']}.jpg"
		# 	if not File.file?(output) then
		# 		image_name = create_image(row['msg'], row['first_name'], row['url'], output)
		# 	end
		#   	screen[:elements] << {
		# 	  "title" 		=> row['msg'],
		# 	  "image_url"  => output
		#   	}
		# end
		user.next_answer('free_text',1,"houston_save_grievance")
		return self.get_screen(screen,user,msg)
	end

	def houston_end(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.next_answer('answer')
		return self.get_screen(screen,user,msg)
	end

	# def houston_menu(msg,user,screen)
	# 	Bot.log.info "#{__method__}"
	# 	screen[:kbd_del]=["houston/menu"] #comment if you want the houston button to be displayed on the houston menu
	# 	user.next_answer('free_text')
	# 	return self.get_screen(screen,user,msg)
	# end

	# def houston_ask_img(msg,user,screen)
	# 	Bot.log.info "#{__method__}"
	# 	# search for an image
	# 	# if image exists:
	# 	if 1==1 then
	# 		screen=self.find_by_name("houston/get_img",self.get_locale(user))
	# 	else
	# 		screen=self.find_by_name("houston/ask_wrong",self.get_locale(user))
	# 	end
	# 	return self.get_screen(screen,user,msg)
	# end

	def houston_save_grievance(msg,user,screen)
		Bot.log.info "#{__method__}"
		txt=user.state['buffer']
		if txt.length > $HOUSTON_TEXT_LIM
			screen=self.find_by_name("houston/too_long",self.get_locale(user))
		else
			user.buffer = txt
			screen=self.find_by_name("houston/ask_themes",self.get_locale(user))
		end
		Bot.log.info "#{__method__}: #{txt}"
		return self.get_screen(screen,user,msg)
	end

	def houston_too_long(msg,user,screen)
		user.next_answer('free_text',1,"houston_save_grievance")
		return self.get_screen(screen,user,msg)
	end

	def houston_ask_themes(msg,user,screen)
		Bot.log.info "#{__method__}"
		themes= []
		results = Bot.db.query("houston_select_cat")
		results.each do |row|
			themes << {
				"type"				=> "postback",
				"title"				=> row['name'],
				"payload"			=> row['id']
			  }
		end
		screen[:attachment] = {
		      "type"			=> "template",
		      "payload" 		=> {
		        "template_type"		=> "button",
		        "text"				=> "A quel thème pouvez-vous l'associer ?",
		        "buttons"			=> themes
		      }
		  }
		user.next_answer('free_text',1,"houston_save_themes")
		return self.get_screen(screen,user,msg)

	end

	def houston_save_themes(msg, usr, screen)
		theme = usr.state['buffer']

		# check theme id and save it
		results = Bot.db.query("houston_select_img", [theme])
		if results[0].empty? then
			screen=self.find_by_name("houston/ask_themes",self.get_locale(usr))
			return screen
		end
		r = Bot.db.query("houston_insert", [usr.id, usr.buffer, results[0]['id']])
		date = Time.parse(r[0]['date']).to_i
		output = "img/#{date}_#{usr.id}.jpg"
		if not File.file?(output) then
			image_name = create_image(usr.buffer, usr.first_name, "#{results[0]['url']}", output)
		end

		# FIXME send
		bash_command = 'curl -F filedata=@%s -F recipient=\'{"id":"%s"}\' \
		 			-F message=\'{"attachment":{"type":"image", "payload":{}}}\' \
					https://graph.facebook.com/v2.7/me/messages?access_token=%s' % [output, usr.fb_id, FB_PAGEACCTOKEN]
		command_result = `#{bash_command}`
		screen=self.find_by_name("houston/delivery",self.get_locale(usr))
		Bot.log.info screen
		return screen
	end

	def houston_feedback(msg, usr, screen)
		Bot.db.query("houston_feedback", [usr.id, usr.state['buffer'], "TRUE"]) 
		screen=self.find_by_name("houston/end", self.get_locale(usr))
		Bot.log.info screen
		return screen
	end

end

include Houston
