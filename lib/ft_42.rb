require "active_support/all"
require "date"
require "action_view"
require "pastel"
require "oauth2"
require "ruby-progressbar"
require "pp"

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
    if (args.size > 2)
      if (args.first == "project")
        puts "This is a big request, it may take a minute or two."
        if (args.include?("after"))
          after = args.pop(3).join(" ")
          after = DateTime.parse(after)
          args.pop
          ft_42 = Client.new(args.second, args.last, after)
        elsif (args.include?("between"))
          before = args.pop(3).join(" ")
          before = DateTime.parse(before)
          args.pop
          after  = args.pop(3).join(" ")
          after  = DateTime.parse(after)
          args.pop
          ft_42  = Client.new(args.second, args.last, after, before)
        else
          ft_42 = Client.new(args.second, args.last)
        end
      else
        ft_42 = Client.new(args.first, args.third)
      end
    else
      ft_42 = Client.new(args.first)
    end
    if (args.first == "project")
      project             = Project.new(ft_42.project)
      project_users       = ProjectUsers.new(ft_42.project_users)
      project_print       = ProjectPrinter.new(project)
      project_users_print = ProjectUsersPrinter.new(project_users)
      project_print.all
      project_users_print.all
    else
      user                = User.new(ft_42.user)
      user_sessions       = UserSessions.new(ft_42.user_sessions)
      user_print          = UserPrinter.new(user)
      user_sessions_print = UserSessionsPrinter.new(user_sessions)
      if args.size == 1
        user_print.all
        user_sessions_print.all
      elsif args.second == "sessions"
        user_sessions_print.sessions
      elsif args.second == "pic"
        if ENV["TERM_PROGRAM"] == "iTerm.app"
          system "iterm2-viewer /nfs/intrav2cdn/users/medium_#{args.first}.jpg"
        end
        user_print.all
        user_sessions_print.all
      elsif args.second == "progress"
        user_print.all
        user_sessions_print.all
        user_sessions_print.progress_bar
      else
        puts"Wrong arguments. Usage ft_42 [USER_LOGIN] [OPTIONAL CMD]"
      end
    end
  end
end


class Client
  attr_reader :input_1, :input_2, :input_3, :input_4, :token

  def initialize(input_1, input_2 = nil, input_3 = nil, input_4 = nil)
    @input_1   = input_1
    @input_2   = input_2
    @input_3   = input_3
    @input_4   = input_4
    @token     = Token.new.token
  end

  def user
    token.get("/v2/users/#{input_1}", params: { per_page: 100 }).parsed
  end

  def user_sessions
    token.get("/v2/users/#{input_1}/locations?range[end_at]=#{time_ago},#{right_now}", params: { per_page: 100 }).parsed
  end

  def project
    token.get("/v2/projects/#{input_1}").parsed
  end

  def campus
    token.get("/v2/campus/#{input_2}").parsed
  end

  def project_users
    user_projects = []
    i = 1
    loop do
      begin
        tries ||= 3
        if input_3
          response = token.get("/v2/projects_users?filter[campus]=#{campus['id']}&filter[project_id]=#{project['id']}&range[created_at]=#{after},#{before}", params: { page: i, per_page: 100 }).parsed
        else
          response = token.get("/v2/projects_users?filter[campus]=#{campus['id']}&filter[project_id]=#{project['id']}", params: { page: i, per_page: 100 }).parsed
        end
      rescue
        puts "Something went wrong..."
        puts "REFRESHING API TOKEN... wait 8 sec"
        sleep 8
        client = OAuth2::Client.new(ENV.fetch("UID42"), ENV.fetch("SECRET42"), site: ENV.fetch("API42"))
        token  = client.client_credentials.get_token
        puts "Retrying request..."
        retry unless (tries -= 1).zero?
      else
        break if response.empty?
        user_projects << response
        i += 1
      end
    end
    user_projects
  end

  private

  def after
    input_3.to_time.to_s.split(" ")[0...-1].join("T")
  end

  def before
    if input_4
      return input_4.to_time.to_s.split(" ")[0...-1].join("T")
    else
      return Time.current.to_s.split(" ")[0...-1].join("T")
    end
  end

  def time_ago
    if input_2
      time = Time.current - (input_2.to_i * 7).days
      return time.to_s.split(" ")[0...-1].join("T")
    else
      return Time.current.beginning_of_week.to_s.split(" ")[0...-1].join("T")
    end
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


class Project
  attr_reader :project

  def initialize(project_response)
    @project = project_response
  end

  def id
    project["id"]
  end

  def name
    project["name"]
  end

  def slug
    project["slug"]
  end

  def tier
    project["tier"]
  end

  def exam
    project["exam"]
  end
end


class Campus
  attr_reader :campus

  def initialize(campus_response)
    @campus = campus_response
  end

  def id
    campus["id"]
  end

  def name
    campus["name"]
  end

  def student_count
    campus["users_count"]
  end
end


class ProjectUsers
  attr_reader :project_users

  def initialize(project_users_response)
    @project_users = project_users_response
    @project_users.flatten!
  end

  def logins
    project_users.map { |user_project| user_project["user"]["login"] }
  end

  def in_progress
    in_progress = project_users.select { |user_project| user_project["status"] == "in_progress" }
    in_progress.map { |user_project| user_project["user"]["login"] }
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
    session["end_at"].to_time unless session["end_at"].nil?
  end

  def host
    session["host"]
  end

  def primary?
    session["primary"]
  end

  def duration
    end_at - begin_at unless end_at.nil?
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
      total_duration += session.duration || 0
    end
    (total_duration / 60 / 60).round
  end
end


class ProjectPrinter
  attr_reader :pastel, :project

  def initialize(project)
    @pastel  = Pastel.new
    @project = project
  end

  def all
    name
    tier
  end

  def name
    puts highlight(project.name)
  end

  def tier
    puts "Difficulty Level: #{project.tier}"
  end

  private

  def highlight(string)
    pastel.bright_green.bold(string)
  end
end

class ProjectUsersPrinter
  attr_reader :pastel, :project_users

  def initialize(project_users)
    @pastel = Pastel.new
    @project_users = project_users
  end

  def all
    usernames
  end

  def usernames
    puts "Currenly working on project:"
    project_users.in_progress.each_with_index do |login, i|
      puts "#{i + 1}. #{login}"
    end
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

  def sessions
    unless user_sessions.sessions.empty?
      user_sessions.sessions.each do |session|
        session_start       = "Session start:    " + session.begin_at.to_time.strftime("%A, %B %d at %I:%M:%S %p")
        session_end         = "Session end:      " + session.end_at.to_time.strftime("%A, %B %d at %I:%M:%S %p")
        duration_in_hours = ActiveSupport::NumberHelper.number_to_rounded((session.end_at.to_time - session.begin_at.to_time) / 60 / 60, :precision => 2)
        puts
        puts "Session duration: " + highlight("#{duration_in_hours} hours")
        puts session_start
        puts session_end
        puts "Session host:     " + session.host + " at " + cluster(session.host)
      end
      puts
    end
  end

  def active_or_last_active
    unless user_sessions.sessions.empty?
      active = false
      user_sessions.sessions.each do |session|
        unless session.end_at.nil?
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
      end

      unless active
        last_active
      end
    end    
  end

  def last_active
    puts "Was last active " + (last_active_time_ago || "") + " at #{last_active_computer}."
  end

  def hours_this_week
    puts "Has " + highlight("#{hours} #{hours_pluralize}") + " in the clusters this week, starting #{last_monday}."

  end

  def progress_bar
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
    highlight("#{ActionView::Base.new.time_ago_in_words(user_sessions.sessions.first.end_at)} ago") unless user_sessions.sessions.first.end_at.nil?
  end

  def last_active_computer
    highlight(cluster(user_sessions.sessions.first.host))
  end

  def last_monday
    Time.current.beginning_of_week.strftime("%A, %B #{Time.current.beginning_of_week.day.ordinalize}")
  end
end
