#!/usr/bin/env ruby
# encoding: UTF-8

# SuccessWhale API function to retrieve column list


get '/v3/listcolumns.?:format?' do

  returnHash = {}

  # Check user is logged in
  if session.has_key?('sw_uid') && session.has_key?('secret')

    # Get parameters
    sw_uid = session[:sw_uid]
    secret = session[:secret]

    # Fetch a DB row for the given uid and secret
    users = CON.query("SELECT * FROM sw_users WHERE sw_uid='#{Mysql.escape_string(sw_uid)}' AND secret='#{Mysql.escape_string(secret)}'")

    if users.num_rows == 1
      # A user matched the supplied sw_uid and secret, so authentication is OK

      user = users.fetch_hash
      returnHash[:success] = true

      # Get the column data and put it into hashes and arrays as appropriate
      columns = user['columns'].split(';')
      returnHash[:columns] = []
      columns.each do |col|
        feeds = col.split('|')
        feedsWithHashes = []
        feeds.each do |feed|
          parts = feed.split(':')
          feedHash = {:service => parts[0],
                      :user => parts[1],
                      :url => parts[2]}
          feedsWithHashes << feedHash
        end
        returnHash[:columns] << feedsWithHashes
      end

    else
      returnHash[:success] = false
      returnHash[:error] = 'User is logged in with invalid credentials.'
    end

  else
    returnHash[:success] = false
    returnHash[:error] = 'User is not logged in. Log in at /v1/login first.'
  end

  makeOutput(returnHash, params[:format], 'user')
end