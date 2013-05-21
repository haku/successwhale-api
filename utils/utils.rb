#!/usr/bin/env ruby
# encoding: UTF-8

# Util functions for the SuccessWhale API.

# Connect to database and all services. Required for every API call.
def connect()

  # Connect to the DB, we will need this for all our API functions
  @db = Mysql.new ENV['DB_HOST'], ENV['DB_USER'], ENV['DB_PASS'], ENV['DB_NAME']

  # Configure a Twitter object
  Twitter.configure do |config|
    config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  end

  # Configure a Facebook object
  @facebookOAuth = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET'])

  # Configure a LinkedIn object
  @facebookClient = LinkedIn::Client.new(ENV['LINKEDIN_APP_KEY'], ENV['LINKEDIN_SECRET_KEY'])
end

# Check authentication was provided by a token parameter, and return data
# (if authentication was successful) or an error message otherwise.
# Note that a failure here need not be terminal - other parts of the API
# may use this to specifically detect users that are *not* logged in if
# they like.
def checkAuth(params)

  returnHash = {}

  begin

    if params.has_key?('token')
      # Fetch a DB row for the given uid and secret
      users = @db.query("SELECT * FROM sw_users WHERE secret='#{Mysql.escape_string(params['token'])}'")

      # If we didn't find a match, set UID to zero
      if users.num_rows == 1
        user = users.fetch_hash
        returnHash[:authenticated] = true
        returnHash[:explicitfailure] = false # Not an explicit failure because it was a success!
        returnHash[:sw_uid] = user['sw_uid'].to_i
      else
        returnHash[:authenticated] = false
        returnHash[:explicitfailure] = true # Explicit failure: token was provided but it was wrong.
        returnHash[:error] = 'A token was provided, but it did not match an entry in the database.'
      end

    else
      returnHash[:authenticated] = false
      returnHash[:explicitfailure] = false # Not an explicit failure, could just be a new / not logged-in user
      returnHash[:error] = 'No token was provided in the parameters. The user is new or not logged in.'
    end

  rescue => e
    returnHash[:authenticated] = false
    returnHash[:explicitfailure] = true # Explicit failure because a proper error occurred.
    returnHash[:error] = e
  end

  return returnHash
end


# Gets all social network accounts for a given user
def getAllAccountsForUser(sw_uid)
  accounts = []

  twitter_users = @db.query("SELECT * FROM twitter_users WHERE sw_uid='#{Mysql.escape_string(sw_uid.to_s)}'")
  twitter_users.each_hash do |user|
    unserializedServiceTokens = PHP.unserialize(user['access_token'])
    userHash = {:service => 'twitter',
                :username => user['username'],
                :uid => user['uid'],
                :servicetokens => unserializedServiceTokens}
    accounts << userHash
  end

  facebook_users = @db.query("SELECT * FROM facebook_users WHERE sw_uid='#{Mysql.escape_string(sw_uid.to_s)}'")
  facebook_users.each_hash do |user|
    userHash = {:service => 'facebook',
                :uid => user['uid'],
                :servicetokens => user['access_token']}

    # Add the Facebook username. This is a bit of a hack because the SWv2
    # database doesn't store usernames for Facebook accounts. TODO fix
    # when migrating database.
    userHash = includeUsernames(userHash)

    accounts << userHash
  end

  linkedin_users = @db.query("SELECT * FROM linkedin_users WHERE sw_uid='#{Mysql.escape_string(sw_uid.to_s)}'")
  linkedin_users.each_hash do |user|
    userHash = {:service => 'linkedin',
                :username => user['username'],
                :uid => user['uid'],
                :servicetokens => user['access_token']}
    accounts << userHash
  end

  return accounts
end

# Returns a user data block for the given sw_uid
def getUserBlock(sw_uid)
  returnHash = {}

  users = @db.query("SELECT * FROM sw_users WHERE sw_uid='#{Mysql.escape_string(sw_uid.to_s)}'")
  if users.num_rows == 1
    user = users.fetch_hash
    returnHash[:success] = true
    returnHash[:userid] = user['sw_uid']
    returnHash[:username] = user['username']
    returnHash[:token] = user['secret']
  else
    returnHash[:success] = false
    returnHash[:error] = 'Tried to look up a SuccessWhale user with an invalid UID.'
  end

  return returnHash
end


# Make JSON or XML from a hash and return it
def makeOutput(hash, format, xmlRoot)
  if format == 'json'
    content_type 'application/json'
    output = hash.to_json
  elsif format == 'xml'
    content_type 'text/xml'
    output = hash.to_xml(:root => "#{xmlRoot}")
  else
    # default to json for now
    content_type 'application/json'
    output = hash.to_json
  end
  return output
end


# Includes the usernames of the feeds as well as just the uids
def includeUsernames(feedHash)
  # Check if we already have a username, if we're supporting a SWv2 database
  # we probably do already
  if !feedHash.has_key?(:username)
    if feedHash[:service] == 'twitter'
      twitter_users = @db.query("SELECT * FROM twitter_users WHERE uid='#{Mysql.escape_string(feedHash[:uid])}'")
      twitter_user = twitter_users.fetch_hash
      feedHash.merge!(:username => twitter_user['username'])
    end
    if feedHash[:service] == 'facebook'
      facebook_users = @db.query("SELECT * FROM facebook_users WHERE uid='#{Mysql.escape_string(feedHash[:uid])}'")
      facebook_user = facebook_users.fetch_hash
      if facebook_user['username'] != nil
        feedHash.merge!(:username => facebook_user['username'])
      else
        # If we're supporting an SWv2 database, we can't get the Facebook
        # username from the table, so make a call to Facebook to get it.
        facebookClient = Koala::Facebook::API.new(facebook_user['access_token'])
        name = facebookClient.get_object("me")['name']
        feedHash.merge!(:username => name)
      end
    end
  end
  return feedHash
end

# Add a new SW user to the database with default settings, and returns
# the sw_uid.
def makeSWAccount()
  token = createToken()
  result = @db.query("INSERT INTO sw_users (secret) VALUES ('#{Mysql.escape_string(token)}')")
  return result.last_id
end

# Creates a random hex token string
def createToken()
  o =  [('0'..'9'),('a'..'f')].map{|i| i.to_a}.flatten
  string  =  (0...50).map{ o[rand(o.length)] }.join
  return string
end

# Adds the default columns for a service to a user's list
def addDefaultColumns(sw_uid, service, service_id)
  users = @db.query("SELECT * FROM sw_users WHERE sw_uid='#{Mysql.escape_string(sw_uid)}'")
  user = users.fetch_hash
  currentCols = user['columns']

  if !currentCols.blank?
    currentCols << ';'
  end

  if service == 'twitter'
    currentCols << "#{service}:#{service_id}:statuses/home_timeline;"
    currentCols << "#{service}:#{service_id}:statuses/mentions;"
    currentCols << "#{service}:#{service_id}:direct_messages"
  elsif service == 'facebook'
    currentCols << "#{service}:#{service_id}:/me/home;"
    currentCols << "#{service}:#{service_id}:/me/feed;"
    currentCols << "#{service}:#{service_id}:notifications"
  end

  @db.query("UPDATE sw_users SET columns='#{Mysql.escape_string(currentCols)}' WHERE sw_uid='#{Mysql.escape_string(sw_uid)}'")
end

# Generates a title for a column based on the feeds it uses
def getColumnTitle(feedsWithHashes)

  # Can't deal with combined feeds very well yet, just throw a generic
  # title unless it's one that we vaguely understand
  if feedsWithHashes.length > 1
    # Mentions & Notifications Feeds
    if feedsWithHashes.all? {|feed| 
      ((feed[:service] == 'twitter' && feed[:url] == 'statuses/mentions') ||
       (feed[:service] == 'facebook' && feed[:url] == 'me/notifications')) }
      return 'Mentions & Notifications'

    else
      return 'Combined Feed'
    end
  end

  # Only one feed, good
  feed = feedsWithHashes[0]

  # Try Twitter first.
  if feed[:service] == 'twitter'
    # Regex matchers for Twitter feeds that have their own title style
    # Handle these first
    listMatch1 = /lists\/([A-Za-z0-9\-_]*)\/statuses/.match(feed[:url])
    listMatch2 = /([A-Za-z0-9\-_]*)\/lists\/([A-Za-z0-9\-_]*)\/statuses/.match(feed[:url])
    listMatch3 = /@([A-Za-z0-9\-_]*)\/([A-Za-z0-9\-_]*)/.match(feed[:url])
    userMatch1 = /user\/([A-Za-z0-9\-_]*)\/statuses/.match(feed[:url])
    userMatch2 = /@([A-Za-z0-9\-_]*)/.match(feed[:url])

    if listMatch1
      return listMatch1[1].gsub(/[\-_]/,' ').titlecase
    elsif listMatch2
      return listMatch2[2].gsub(/[\-_]/,' ').titlecase
    elsif listMatch3
      return listMatch3[2].gsub(/[\-_]/,' ').titlecase
    elsif userMatch1
      return "@#{userMatch1[1]}"
    elsif userMatch2
      return "@#{userMatch2[1]}"
    else
      # Not a list or a user, so treat this as the requesting user's feed
      title = "@#{feed[:username]}'s "
      if feed[:url] == 'statuses/home_timeline'
        title << 'Home Timeline'
      elsif feed[:url] == 'statuses/user_timeline'
        title << 'Timeline'
      elsif feed[:url] == 'statuses/mentions'
        title << 'Mentions'
      elsif feed[:url] == 'direct_messages'
        title << 'Direct Messages'
      elsif feed[:url] == 'direct_messages/sent'
        title << 'Sent Messages'
      else
        title = 'Unknown Feed'
      end
      return title
    end
  elsif feed[:service] == 'facebook'
    title = "#{feed[:username]}'s "
    if feed[:url] == 'me/home'
      title << 'Home Timeline'
    elsif feed[:url] == 'me'
      title << 'Wall'
    elsif feed[:url] == 'me/notifications'
      title << 'Notifications'
    elsif feed[:url] == 'me/events'
      title << 'Events'
    else
      title = 'Unknown Feed'
    end
  else
    return 'Unknown Feed'
  end
end
