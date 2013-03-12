#!/usr/bin/env ruby
# encoding: UTF-8

# SuccessWhale's API, powered by Sinatra
# Written by Ian Renton
# BSD licenced (See the LICENCE file)
# https://github.com/ianrenton/successwhale-api

require 'sinatra'
require 'mysql'
require 'digest/md5'
require 'json'
require 'builder'
require 'active_support/core_ext'

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

# Import API function files.  These contain all the main Sinatra processing
# code.
require_relative 'apifuncs/v3/authenticate-get'
require_relative 'apifuncs/v3/authenticate'
require_relative 'apifuncs/v3/listcolumns'
require_relative 'apifuncs/v3/getbannedphrases'


# 404
not_found do
  '<h1>SuccessWhale API - Invalid Request</h3><p>You have made an invalid API call. For a list of valid calls, please see the <a href="https://github.com/ianrenton/successwhale-api/blob/master/APIDOCS.md">API docs</a>.</p>'
end


# Check authentication was provided by session or params, if so return sw_uid
# otherwise return 0.
def checkAuth(session, params)

  if session.has_key?('sw_uid') && session.has_key?('secret')
    sw_uid = session[:sw_uid]
    secret = session[:secret]
  elsif params.has_key?('sw_uid') && params.has_key?('secret')
    sw_uid = params[:sw_uid]
    secret = params[:secret]
  else
    sw_uid = 0
    secret = ""
  end

  # Fetch a DB row for the given uid and secret
  users = CON.query("SELECT * FROM sw_users WHERE sw_uid='#{Mysql.escape_string(sw_uid)}' AND secret='#{Mysql.escape_string(secret)}'")

  # If we didn't find a match, set UID to zero
  if users.num_rows != 1
    sw_uid = 0
  end

  return sw_uid.to_i
end


# Utility function: Make JSON or XML and return it
def makeOutput(hash, format, xmlRoot)
  if format == 'json'
    output = hash.to_json
  elsif format == 'xml'
    output = hash.to_xml(:root => "#{xmlRoot}")
  else
    # default to json for now
    output = hash.to_json
  end
  return output
end
