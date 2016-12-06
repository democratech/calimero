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
					:f1_ans=>"1",
					:f2_ans=>"2",
					:f3_ans=>"3",
					:f4_ans=>"4",
					:f5_ans=>"5",
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
					:feedback=><<-END,
Je viens d'être créée, j'ai besoin de votre ressenti pour m'améliorer. Que pensez-vous de votre expérience de conversation ?
END
				}
			},
			:fr=>{
				:houston=>{
					:f1_ans=>"1",
					:f2_ans=>"2",
					:f3_ans=>"3",
					:f4_ans=>"4",
					:f5_ans=>"5",
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
				:f1=>{
					:answer=>"houston/f1_ans",
					:callback=>"houston/feedback_save",
				},
				:f2=>{
					:answer=>"houston/f2_ans",
					:callback=>"houston/feedback_save",
				},
				:f3=>{
					:answer=>"houston/f3_ans",
					:callback=>"houston/feedback_save",
				},
				:f4=>{
					:answer=>"houston/f4_ans",
					:callback=>"houston/feedback_save",
				},
				:f5=>{
					:answer=>"houston/f5_ans",
					:callback=>"houston/feedback_save",
				},
				:ask_themes=>{
					:callback=>"houston/ask_themes"
				},
				:carousel=>{},
				:delivery=>{ :jump_to=>"houston/feedback"},
				:end=>{},
				:feedback=>{
					:callback=>"houston/feedback",
					:kbd=>["houston/f1","houston/f2","houston/f3","houston/f4","houston/f5"],
					:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true}
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

		user.next_answer('free_text',1,"houston_save_grievance")
		return self.get_screen(screen,user,msg)
	end

	def houston_end(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.next_answer('answer')
		return self.get_screen(screen,user,msg)
	end

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
		Bot.log.info "#{__method__}"
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

	def houston_feedback(msg, user, screen)
		Bot.log.info "#{__method__}"
		# user.next_answer('answer')
		user.next_answer('free_text',1,"houston/feedback_save")
		return self.get_screen(screen,user,msg)
	end

	def houston_feedback_save(msg, usr, screen)
		Bot.log.info "#{__method__}"
		Bot.db.query("houston_feedback", [usr.id, usr.state['buffer'], "TRUE"])
		screen=self.find_by_name("houston/end", self.get_locale(usr))
		Bot.log.info screen
		return screen
	end

end

include Houston
