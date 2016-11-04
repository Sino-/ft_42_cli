require "active_support/all"
require "action_view"
require "pastel"
require "oauth2"
require "ruby-progressbar"

include ActionView::Helpers::DateHelper

HOURS_NEEDED = 38
USERNAME     = ARGV[0];
UID          = ENV["UID"]
SECRET       = ENV["SECRET"]

client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")
token  = client.client_credentials.get_token

time_ago  = Time.current.beginning_of_week.to_s.split(" ")[0...-1].join("T")
right_now = Time.current.to_s.split(" ")[0...-1].join("T")

sessions = token.get("/v2/users/#{USERNAME}/locations?range[begin_at]=#{time_ago},#{right_now}", params: { per_page: 60 }).parsed

duration = 0
sessions.each do |session|
  begin_at =  session["begin_at"].to_time
  end_at   =  session["end_at"].to_time
  duration += (end_at - begin_at)
end

pastel = Pastel.new

puts pastel.bright_green("#{USERNAME} has ", pastel.bold("#{distance_of_time_in_words(duration)}"), " in the clusters this week")

hours = (duration / 60 / 60).round
percent_complete = ((hours.to_f / HOURS_NEEDED.to_f) * 100).round

progressbar_needed = ProgressBar.create(length: 60, format: "%t: |%B| 38 hours")
percent_complete.times { progressbar_needed.increment }
puts pastel.bright_green(progressbar_needed)
