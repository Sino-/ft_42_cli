require "active_support/all"
require "action_view"
require "pastel"
require "oauth2"
require "ruby-progressbar"

class FT_42
  def initialize(*args)
    url_42       = "https://api.intra.42.fr"
    uid_42       = ENV.fetch("FT42_UID")
    secret_42    = ENV.fetch("FT42_SECRET")
    hours_needed = 38

    username = args.first

    # get token
    client = OAuth2::Client.new(uid_42, secret_42, site: url_42)
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

    puts "Has " + pastel.bright_green.bold("#{hours} #{hours == 1 ? 'hour' : 'hours'}") + " in the clusters this week, starting #{Time.current.beginning_of_week.strftime("%A, %B #{Time.current.beginning_of_week.day.ordinalize}")}. #{'Go to sleep.' if hours > 60}"

    percent_complete = ((hours.to_f / hours_needed.to_f) * 100).round
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

class API_42
end

class User
end

class Session
end

class UserPrinter
end

class SessionPrinter
end
