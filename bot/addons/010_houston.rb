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
			"houston_select_dol" => "SELECT * FROM #{DB_PREFIX}doleances where usr_id=$1",
			"houston_select_img" => "SELECT * FROM #{DB_PREFIX}images where id=$1",
			"houston_insert"  => "INSERT INTO #{DB_PREFIX}doleances (usr_id, msg, img_id) VALUES ($1, $2, $3) returning id"
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
					:delivery => "Et voila !\n",
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
J'espère que vous êtes satifait(e) de moi. À bientôt !
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
				:delivery=>{ :jump_to=>"houston/end"},
				:end=>{}


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
				:title 		=> "Ecrivez votre doleance",
				:image_url  => "http://guhur.net/img/megaphone.png",
			},
			{
				"title" 		=> "On a faim",
				"image_url"  => "http://guhur.net/img/output.jpg"
			},
			{
				"title" 		=> "On a faim",
				"image_url"  => "http://guhur.net/img/output.jpg"
			}
		]
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
		#Bot::Db.query("save_grievance", txt, user.id, theme)
		#user.next_answer('free_text',1,"houston_save_txt")
		return self.get_screen(screen,user,msg)
	end

	def houston_too_long(msg,user,screen)
		user.next_answer('free_text',1,"houston_save_grievance")
		return self.get_screen(screen,user,msg)
	end

	def houston_ask_themes(msg,user,screen)
		Bot.log.info "#{__method__}"
		# TODO get themes from database
		screen[:attachment] = {
		      "type"			=> "template",
		      "payload" 		=> {
		        "template_type"		=> "button",
		        "text"				=> "A quel theme pouvez-vous l'associer ?",
		        "buttons"			=> [{
		            "type"				=> "postback",
		            "title"				=> "Societe",
		            "payload"			=> "societe"
		          },
				  {
					  "type" 					=> "postback",
					  "title"					=> "Environnement",
					  "payload"				=> "environnement"
				  }]
		      }
		  }
		user.next_answer('free_text',1,"houston_save_themes")
		return self.get_screen(screen,user,msg)

	end

	def houston_save_themes(msg, usr, screen)
		# TODO save themes and grievances inside the database
		theme = usr.state['buffer']

		# create image
		image_url = "https://s3.eu-central-1.amazonaws.com/laprimaire/themes/environnement.jpg"
		output = "output.jpg"
		image_name = create_image(usr.buffer, usr.first_name, image_url, output)

		# FIXME send
		bash_command = 'curl -F filedata=@%s -F recipient=\'{"id":"%s"}\' \
		 			-F message=\'{"attachment":{"type":"image", "payload":{}}}\' \
					https://graph.facebook.com/v2.7/me/messages?access_token=%s' % [output, usr.id, FB_PAGEACCTOKEN]
		command_result = `#{bash_command}`
		Bot.log.info bash_command
		screen=self.find_by_name("houston/delivery",self.get_locale(usr))
		return screen
	end


end

include Houston
