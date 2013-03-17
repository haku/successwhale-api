#!/usr/bin/env ruby
# encoding: UTF-8

# SuccessWhale's API, powered by Sinatra
# Written by Ian Renton
# BSD licenced (See the LICENCE.md file)
# Homepage: https://github.com/ianrenton/successwhale-api

require 'sinatra'
require 'mysql'
require 'digest/md5'
require 'json'
require 'xmlsimple'
require 'builder'
require 'active_support/core_ext'
require 'php_serialize'
require 'twitter'
require 'rack/throttle'
require_relative 'utils'
require_relative 'classes/item'

# Throttle clients to max. 1000 API calls per hour
use Rack::Throttle::Hourly,   :max => 1000

# Get the configuration
if File.file?('config_local.rb')
  require_relative 'config_local'
else
  abort('API server is not configured. Edit the values in config_local_sample.rb and rename the file to config_local.rb.')
end

# Enable sessions so that we can store the user's authentication in a cookie
enable :sessions

# Globals
NOT_AUTH_ERROR = 'User is not logged in. Log in at /v3/authenticate first, and either use cookies to preserve the session, or provide sw_uid and secret as paramters to each API call.'

# Connect to the DB, we will need this for all our API functions
CON = Mysql.new DB_HOST, DB_USER, DB_PASS, DB_NAME

# Configure a Twitter object
Twitter.configure do |config|
  config.consumer_key = TWITTER_CONSUMER_KEY
  config.consumer_secret = TWITTER_CONSUMER_SECRET
end

# Import API function files.  These contain all the main Sinatra processing
# code.
require_relative 'apifuncs/v3/authenticate-get'
require_relative 'apifuncs/v3/authenticate'
require_relative 'apifuncs/v3/accounts'
require_relative 'apifuncs/v3/columns'
require_relative 'apifuncs/v3/bannedphrases'
require_relative 'apifuncs/v3/posttoaccounts'
require_relative 'apifuncs/v3/displaysettings'
require_relative 'apifuncs/v3/feed'


# 404
not_found do
  '<h1>SuccessWhale API - Invalid Request</h3><p>You have made an invalid API call. For a list of valid calls, please see the <a href="https://github.com/ianrenton/successwhale-api/blob/master/APIDOCS.md">API docs</a>.</p>'
end
