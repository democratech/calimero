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

module Bot
	class Db
		@@db=nil
		@@queries={}

		def initialize
			return unless DATABASE
			Bot.log.debug "connect to database : #{DBNAME} with user : #{DBUSER}"
			begin
				@@db=PG.connect(
					"dbname"=>DBNAME,
					"user"=>DBUSER,
					"password"=>DBPWD,
					"host"=>DBHOST,
					"port"=>DBPORT
				)
			rescue PG::Error => e
			    Bot.log.error e.message
			end
		end

		def is_connected?
			return DATABASE
		end

		def self.load_queries
			Bot::Users.load_queries
		end

		def prepare(name,query)
			#Bot.log.debug "#{__method__}: #{name} / query: #{query}"
			@@queries[name]=query
		end

		def close
			@@db.close() unless @@db.nil?
		end

		def query(name,params = [])
			Bot.log.info "#{__method__}: #{name} / values: #{params}"
			#Bot.log.info @@queries
			if params.empty?
				return @@db.exec(@@queries[name])
			else
				return @@db.exec_params(@@queries[name],params)
			end
		end
	end
end
