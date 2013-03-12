#!/usr/bin/env ruby
# encoding: UTF-8

# SuccessWhale API configuration parameters
# Fill in the values in this file and rename it to config_local.rb
# before running the app.

# Salt for password strings, to increase resilience against rainbow table
# attacks.  This can be any (preferably long) ASCII string
PASSWORD_SALT = ''

# mySQL connection parameters
DB_HOST = '' # e.g. 'localhost'
DB_USER = '' # e.g. 'myuser'
DB_PASS = '' # e.g. 'mypassword'
DB_NAME = '' # e.g. 'successwhaledb'

# Twitter REST API keys
TWITTER_CONSUMER_KEY = ''    # Set up your app on http://dev.twitter.com
TWITTER_CONSUMER_SECRET = '' # to get these values for your app