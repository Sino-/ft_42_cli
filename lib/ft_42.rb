require "active_support/all"
require "action_view"
require "pastel"
require "oauth2"
require "ruby-progressbar"

module Constants
  URL_42       = "https://api.intra.42.fr"
  UID_42       = ENV.fetch("FT42_UID")
  SECRET_42    = ENV.fetch("FT42_SECRET")
  HOURS_NEEDED = 38
end

class FT_42

  include Constants

  # change to start
  def initialize(*args)
    # ft_42                 = Client.new(args.first)
    # user                  = User.new(ft_42.user)
    # user_sessions         = UserSessions.new(ft_42.user_sessions)
    # user_print            = UserPrinter.new(user)
    # user_sessions_print   = UserSessionsPrinter.new(user_sessions)
    # user_print.all
    # user_sessions_print.all

    username = args.first

    # get token
    client = OAuth2::Client.new(UID_42, SECRET_42, site: URL_42)
    token  = client.client_credentials.get_token

    # helpers
    time_ago  = Time.current.beginning_of_week.to_s.split(" ")[0...-1].join("T")
    right_now = Time.current.to_s.split(" ")[0...-1].join("T")

    # Make requests
    user     = token.get("/v2/users/#{username}", params: { per_page: 100 }).parsed
    sessions = token.get("/v2/users/#{username}/locations?range[begin_at]=#{time_ago},#{right_now}", params: { per_page: 100 }).parsed
    phone    = %x(ldapsearch -Q uid=#{username} | grep mobile).split.last

    # calculate hours
    duration = 0
    sessions.each do |session|
      begin_at =  session["begin_at"].to_time
      end_at   =  session["end_at"].to_time
      duration += (end_at - begin_at)
    end
    hours = (duration / 60 / 60).round

    # currently working on
    in_progress = user["projects_users"].select { |project| project["status"] == "in_progress" }.map { |in_prog| in_prog["project"]["name"] }
    in_progress = ["something, maybe.."] if in_progress.empty?

    # printer
    pastel = Pastel.new

    puts pastel.bright_green.bold("#{user['first_name']} #{user['last_name']}")

    # is active?
    unless sessions.empty?
      active = false
      sessions.each do |session|
        if session["begin_at"].to_time - session["end_at"].to_time == -600.0
          unless active
            puts "Is #{pastel.bright_green.bold('active')} at " + pastel.bright_green.bold("#{cluster(session['host'])}") + " computer #{session['host']}."
          end
          unless session["primary"]
            puts pastel.red.bold("Warning: Logged in on more than one computer. Please logout from #{session['host']} ASAP.")
          end
          active = true
        end
      end

      unless active
        puts "Was last active " + pastel.bright_green.bold("#{ActionView::Base.new.time_ago_in_words(sessions.first['end_at'].to_time)} ago") + " at #{pastel.bright_green.bold(cluster(sessions.first['host']))}."
      end
    end

    puts "Has " + pastel.bright_green.bold("#{hours} #{hours == 1 ? 'hour' : 'hours'}") + " in the clusters this week, starting #{Time.current.beginning_of_week.strftime("%A, %B #{Time.current.beginning_of_week.day.ordinalize}")}. #{'Go to sleep.' if hours > 60}"

    percent_complete = ((hours.to_f / HOURS_NEEDED.to_f) * 100).round
    if (percent_complete <= 100)
      progressbar_needed = ProgressBar.create(progress_mark: "█", length: 60, format: "%t: |" + pastel.red("%B") + "| #{hours}/38 hours")
      percent_complete.times { progressbar_needed.increment }
      puts progressbar_needed
    end

    puts "Is working on #{pastel.bright_green.bold(in_progress.to_sentence)}."
    puts "Is level #{pastel.bright_green.bold(ActiveSupport::NumberHelper.number_to_rounded(user['cursus_users'].select { |cursus| cursus['cursus']['name'] == "42" }.first['level'], precision: 2))}"
    puts "Has #{pastel.bright_green.bold(ActionView::Base.new.pluralize(user['correction_point'], 'correction point'))}.#{' *grabs pitchfork*' if user['correction_point'] > 6}"
    puts "You can contact #{user['first_name'].titleize} at #{pastel.bright_green.bold(ActiveSupport::NumberHelper.number_to_phone(phone))}."
  end

  private

  def cluster(host)
    case true
    when host.include?("z1") then "Cluster 1"
    when host.include?("z2") then "Cluster 2"
    when host.include?("z3") then "Cluster 3"
    when host.include?("z3") then "Cluster 4"
    else host
    end
  end
end

# class Client
#   attr_reader :username

#   def initialize(username)
#     @username = username
#   end

#   def user
#   end

#   def user_sessions_this_week
#   end
# end

# class Token
#   def initialize(uid, secret, url)

#   end
# end

# class User

#   attr_reader :user

#   def initialize(user_response)
#     @user = user_response
#   end

#   def current_projects
#   end

#   def first_name
#   end

#   def last_name
#   end

#   def full_name
#   end

#   def correction_points
#   end

#   def level
#   end

#   def phone
#   end

#   def active?
#   end

#   def last_active_session
#   end

#   def hours_this_week
#   end
# end

# class Session
#   attr_reader :session

#   def initialize(session)
#     @session = session
#   end

#   def host
#   end

#   def duration_in_hours
#   end
# end

# class UserSessions
#   attr_reader :user_sessions

#   def initialize(user_sessions_response)
#     @user_sessions = user_sessions_response
#   end

#   def total_hours_this_week
#   end
# end

# class UserPrinter
#   attr_reader :pastel

#   # include ActiveView and ActiveSupport

#   def initialize
#     @pastel = Pastel.new
#   end
# end

# class UserSessionsPrinter
# end
