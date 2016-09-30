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
				"users_select" => "SELECT * FROM #{DB_PREFIX}users where id=$1",
				"users_insert"  => "INSERT INTO #{DB_PREFIX}users (first_name, last_name, email) VALUES ($1, $2, $3) returning id"
			}
			queries.each { |k,v| Bot.db.prepare(k,v) }
		end


		def initialize()
			@users={}
			if Bot.db.is_connected? then
				Users::load_queries
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
			res=self.search(user)

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

		def search(user)
			if @users.key?(user.id) then
				return @users[user.id]

			elsif Bot.db.is_connected? then
				if user.fb_id != -1 then
					user = Bot.bots[FBMESSENGER].load(user)
				end
				if user.tg_id != -1 then
					user = Bot.bots[TELEGRAM].load(user)
				end
				if user.id != -1 then
					user = Bot::Users.load(user)
					# we add this user in our hash to load it directly next time
					@users[user.id] = user
					return user
				end
			end
			return nil
		end

		def self.load(user)
			results = Bot.db.query("users_select", [user.id])
			results.each do |row|
			  user.first_name = row['first_name']
			  user.last_name  = row['last_name']
			  user.mail 	  = row['email']
			  if user.fb_id   == -1 then
				  res = Bot.bots[FBMESSENGER].load(user)
			  end
			  if user.tg_id == -1 then
				  res = Bot.bots[TELEGRAM].load(user)
			  end
		    end
			return user
		end

		# ----------------------------------------------------------------------
	end
end
