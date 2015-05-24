class SessionsController < ApplicationController
  def create
  	#What data comes back from OmniAuth?     
    @auth = request.env["omniauth.auth"]
    #Use the token from the data to request a list of calendars
    @token = @auth["credentials"]["token"]
    
    owner = User.find_by(email: @auth["info"]["email"])
    if (owner.nil?)
      owner = User.create({
        email: @auth["info"]["email"],
        name: @auth["info"]["name"]
      })
    end

    session[:user_id] = owner.uuid

    session[:token] = @token

    redirect_to :back

  end

  def destroy
    session[:token] = nil
  	session[:user_id] = nil
  	redirect_to root_path
  end
end
