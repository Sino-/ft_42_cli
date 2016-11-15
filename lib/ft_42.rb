require "active_support/all"
require "action_view"
require "pastel"
require "oauth2"
require "ruby-progressbar"

module Constants
  URL_42            = "https://api.intra.42.fr"
  UID_42            = ENV.fetch("FT42_UID")
  SECRET_42         = ENV.fetch("FT42_SECRET")
  HOURS_NEEDED      = 38
  HOURS_ACHIEVEMENT = 90
  HOURS_CHALLENGE   = 100
end


class FT_42
  def initialize(*args)
    ft_42               = Client.new(args.first)
    user                = User.new(ft_42.user)
    user_sessions       = UserSessions.new(ft_42.user_sessions)
    user_print          = UserPrinter.new(user)
    user_sessions_print = UserSessionsPrinter.new(user_sessions)
    if args.size == 1
      user_print.all
      user_sessions_print.all
    end
  end
end


class Client
  attr_reader :username, :token

  def initialize(username)
    @username = username
    @token    = Token.new.token
  end

  def user
    puts "Getting #{username}'s info..."
    token.get("/v2/users/#{username}", params: { per_page: 100 }).parsed
  end

  def user_sessions
    puts "Getting #{username}'s session this week..."
    token.get("/v2/users/#{username}/locations?range[end_at]=#{time_ago},#{right_now}", params: { per_page: 100 }).parsed
  end

  private

  def time_ago
    Time.current.beginning_of_week.to_s.split(" ")[0...-1].join("T")
  end

  def right_now
    Time.current.to_s.split(" ")[0...-1].join("T")
  end
end


class Token
  include Constants

  attr_reader :token

  def initialize
    client = OAuth2::Client.new(UID_42, SECRET_42, site: URL_42)
    @token = client.client_credentials.get_token
  end
end



class User
  attr_reader :user

  def initialize(user_response)
    @user = user_response
  end

  def current_projects
    if projects_in_progress.empty?
      return ["something, maybe..."]
    else
      return projects_in_progress.map { |in_prog| in_prog["project"]["name"] }
    end
  end

  def first_name
    user["first_name"]
  end

  def last_name
    user["last_name"]
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def correction_points
    user["correction_point"]
  end

  def level
    if pisciner?
      cursus("Piscine C").first["level"] if pisciner?
    elsif cadet?
      cursus("42").first["level"]
    else
      0
    end
  end

  def phone
    %x(ldapsearch -Q uid=#{username} | grep mobile).split.last
  end

  def pisciner?
    cursus("42").empty?
  end

  def cadet?
    !pisciner?
  end

  private

  def cursus(name)
    user['cursus_users'].select { |cursus| cursus['cursus']['name'] == name }
  end

  def projects_in_progress
    user["projects_users"].select { |project| project["status"] == "in_progress" }
  end
end



class Session
  attr_reader :session

  def initialize(session)
    @session = session
  end

  def begin_at
    session["begin_at"].to_time
  end

  def end_at
    session["end_at"].to_time
  end

  def host
    session["host"]
  end

  def primary?
    session["primary"]
  end

  def duration
    end_at - begin_at
  end
end



class UserSessions
  attr_reader :user_sessions

  def initialize(user_sessions_response)
    @user_sessions = user_sessions_response
  end

  def sessions
    user_sessions.map { |session| Session.new(session) }
  end

  def total_hours_this_week
    total_duration = 0
    sessions.each do |session|
      total_duration += session.duration
    end
    (total_duration / 60 / 60).round
  end
end



class UserPrinter
  attr_reader :pastel, :user

  def initialize(user)
    @pastel = Pastel.new
    @user = user
  end

  def all
    name
    current_projects
    level
    correction_points
  end

  def name
    puts highlight(user.full_name)
  end

  def current_projects
    puts "Is working on #{highlight(user.current_projects.to_sentence)}."
  end

  def level
    puts "Is level #{highlight(ActiveSupport::NumberHelper.number_to_rounded(user.level, precision: 2))}"
  end

  def correction_points
    print "Has #{highlight(ActionView::Base.new.pluralize(user.correction_points, 'correction point'))}."
    grabs_pitchfork if user.correction_points > 8
    puts
  end

  def contact
    puts "You can contact #{user.first_name.titleize} at #{highlight(ActiveSupport::NumberHelper.number_to_phone(user.phone))}."
  end

  private

  def highlight(string)
    pastel.bright_green.bold(string)
  end

  def grabs_pitchfork
    print " *grabs pitchfork*"
  end
end



class UserSessionsPrinter
  include Constants

  attr_reader :pastel, :user_sessions

  def initialize(user_sessions)
    @pastel = Pastel.new
    @user_sessions = user_sessions
  end

  def all
    active_or_last_active
    hours_this_week
  end

  def active_or_last_active
    unless user_sessions.sessions.empty?
      active = false
      user_sessions.sessions.each do |session|
        if session.end_at - session.begin_at == 600.0
          unless active
            puts "Is #{highlight('active')} at " + highlight("#{cluster(session.host)}") + " computer #{session.host}."
          end
          unless session.primary?
            puts warning("Warning: Logged in on more than one computer. Please logout from #{session.host} ASAP.")
          end
          active = true
        end
      end

      unless active
        last_active
      end
    end    
  end

  def last_active
    puts "Was last active " + last_active_time_ago + " at #{last_active_computer}."
  end

  def hours_this_week
    puts "Has " + highlight("#{hours} #{hours_pluralize}") + " in the clusters this week, starting #{last_monday}."
    hours_progress_bar
    hours_progress_bar_achievement
    hours_progress_bar_challenge
  end

  def hours_progress_bar
    percent_complete = ((hours.to_f / HOURS_NEEDED.to_f) * 100).round
    if (percent_complete <= 100)
      progressbar_needed = ProgressBar.create(progress_mark: "█", length: 64, format: "%t:     |" + warning("%B") + "| #{hours}/38 hours")
      percent_complete.times { progressbar_needed.increment }
      print "Minimum "
      print progressbar_needed
      puts
    end
  end

  def hours_progress_bar_achievement
    percent_complete = ((hours.to_f / HOURS_ACHIEVEMENT.to_f) * 100).round
    if (percent_complete <= 100)
      progressbar_needed = ProgressBar.create(progress_mark: "█", length: 60, format: "%t: |" + warning("%B") + "| #{hours}/90 hours")
      percent_complete.times { progressbar_needed.increment }
      print "Achievement "
      print progressbar_needed
      puts
    end
  end

  def hours_progress_bar_challenge
    percent_complete = ((hours.to_f / HOURS_CHALLENGE.to_f) * 100).round
    if (percent_complete <= 100)
      progressbar_needed = ProgressBar.create(progress_mark: "█", length: 63, format: "%t:   |" + warning("%B") + "| #{hours}/100 hours")
      percent_complete.times { progressbar_needed.increment }
      print "Challenge "
      print progressbar_needed
      puts
    end
  end

  def sessions_this_week
    unless user_sessions.sessions.empty?
      user_sessions.sessions.each do |session|
        puts "#{session.host} from #{session.begin_at} to #{session.end_at}"
      end
    end
  end

  private

  def hours
    user_sessions.total_hours_this_week
  end

  def hours_pluralize
    if hours == 1
      "hour"
    else
      "hours"
    end
  end

  def highlight(string)
    pastel.bright_green.bold(string)
  end

  def warning(string)
    pastel.red(string)
  end

  def cluster(host)
    case true
    when host.include?("z1") then "Cluster 1"
    when host.include?("z2") then "Cluster 2"
    when host.include?("z3") then "Cluster 3"
    when host.include?("z3") then "Cluster 4"
    else host
    end
  end

  def last_active_time_ago
    highlight("#{ActionView::Base.new.time_ago_in_words(user_sessions.sessions.first.end_at)} ago")
  end

  def last_active_computer
    highlight(cluster(user_sessions.sessions.first.host))
  end

  def last_monday
    Time.current.beginning_of_week.strftime("%A, %B #{Time.current.beginning_of_week.day.ordinalize}")
  end
end
