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

# define a class for managing several users


module Bot
	class Users
		def self.load_queries
			queries={
				"users_select" => "SELECT * FROM #{DB_PREFIX}users",
				"users_insert"  => "INSERT INTO #{DB_PREFIX}users (first_name, last_name, email) VALUES (?,?,?) returning id"
			}
			queries.each { |k,v| Bot.db.prepare(k,v) }
		end


		def initialize()
			@users={}
			# load all users from database
			if Bot.db.is_connected? then
				Users::load_queries
				Bot.log.info "loading users"
				results = Bot.db.query("users_select")
				results.each do |row|
				  user     	  	  = Bot::User.new()
				  user.id 		  = row['id']
				  user.first_name = row['first_name']
				  user.last_name  = row['last_name']
				  user.mail 	  = row['email']
				  Bot.bots.each do |key,bot|
					  user 		  = bot.load(user)
				  end
				  @users[user.id] = user
				  Bot.log.info user
				end
			end
		end

		def add(user)
			if Bot.db.is_connected? then
				params = [
					user.first_name,
					user.last_name,
					user.mail
				]
				res = Bot.db.query("users_insert", params)
				user.id = res[0]['id']
				return Bot.bots[user.bot].add(user)
			end
			return user
		end

		# given a User instance with a Bot name and an ID, we look into the database to load missing informations, or to create it in the database
		def open(user)
			res=self.search({
				:by=>"user_id",
				:target=> user.id
			})
			if res.nil? then # new user
				Bot.bots[user.bot].create(user)
				self.add(user)
			else
				user = res.clone
			end
			@users[user.id]=user
			return user
		end

		def close(user)
			user.close()
		end

		def search(query)
			return @users[query[:target]]
		end
	end
end
