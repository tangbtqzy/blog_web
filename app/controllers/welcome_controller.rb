class WelcomeController < ApplicationController
	def index
		scheduler = Rufus::Scheduler.new
		scheduler.in '20m' do
			puts "test_schedule"
		end

		scheduler.every '5m' do
		  puts 'check blood pressure'
		end
	end
end
