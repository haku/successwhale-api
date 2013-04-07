#!/usr/bin/env ruby
# encoding: UTF-8

# SuccessWhale API function to authenticate a user using with Facebook.
# Comes in two GET forms - one, when no parameters are provided, which
# returns the URL to visit to authorise the app. The second form, when
# a code parameter is supplied, is used when data is being returned from
# Facebook via callback.


get '/v3/authwithfacebook.?:format?' do

  returnHash = {}

  begin

    connect()

    if !params.has_key?('code')
      # No code provided, so this isn't a callback - return a URL that
      # the user can be sent to to kick off authentication, unless there
      # was an explicit auth failure. (New users and properly authenticated
      # users will see the URL, auth failures and errors will see the error)
      authResult = checkAuth(session, params)
      if !authResult[:explicitfailure]
        status 200
        returnHash[:success] = true
        returnHash[:url] = @facebookOAuth.url_for_oauth_code(:callback => request.url, :permissions => FACEBOOK_PERMISSIONS)
      else
        status 401
        returnHash[:success] = false
        returnHash[:error] = authResult[:error]
      end
    else
      # A code was returned, so let's validate it and process the login
        token = @facebookOAuth.get_access_token(params[:code], {:redirect_uri => request.url})
        status 200
        returnHash[:success] = true
        returnHash[:token] = token
    end

  rescue => e
    status 500
    returnHash[:success] = false
    returnHash[:error] = e.message
    returnHash[:errorclass] = e.class
  end

  makeOutput(returnHash, params[:format], 'authinfo')
end