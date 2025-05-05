require_relative 'application_controller'
require_relative '../models/user'

class UsersController < ApplicationController
  get '/users/signup' do
    redirect to "/users/#{current_user.id}" if logged_in?
    erb :'users/signup'
  end

  post '/users/signup' do
    if params[:username].to_s.strip.empty? || params[:password].to_s.strip.empty?
      @signup_error = "Don't leave username or password blank!"
      return erb :'users/signup'
    end

    if User.find_by_username(params[:username])
      @signup_error = "That username is taken. Try again."
      return erb :'users/signup'
    end

    user = User.create(params[:username], params[:password])
    session[:user_id] = user.id
    redirect to "/users/#{user.id}"
  end

  get '/users/:id' do
    redirect to '/' unless logged_in?
    @user = User.find(params[:id])
    halt 404, "Couldn't find the user" unless @user
    erb :'users/show'
  end
end