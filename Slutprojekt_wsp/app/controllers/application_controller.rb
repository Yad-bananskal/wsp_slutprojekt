require 'sinatra/base'
require 'bcrypt'
require 'securerandom'
require_relative '../../config/database'

class ApplicationController < Sinatra::Base
  configure do
    set :public_folder, 'public'
    set :views, 'views'
    set :method_override, true
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  helpers do
    def current_user
      return unless session[:user_id]
      User.find(session[:user_id])
    end

    def logged_in?
      !!session[:user_id]
    end

    def admin_user?
      logged_in? && current_user.role == 'admin'
    end

    def total_cart_items
      return 0 unless logged_in?
      current_user.cart_total_items
    end

    def require_login
      redirect to('/welcome') unless logged_in?
    end

    def require_admin
      redirect to('/unauthorized') unless admin_user?
    end

    def set_login_error(message, cooldown = nil)
      @login_error = message
      session[:login_cooldown] = Time.now + cooldown if cooldown
    end
  end

  get '/' do
    redirect to '/shop'
  end

  get '/unauthorized' do
    erb :unauthorized
  end

  get '/welcome' do
    if logged_in?
      redirect admin_user? ? '/admin' : "/users/#{current_user.id}"
    else
      if session[:login_cooldown] && Time.now < session[:login_cooldown]
        @cooldown_remaining = (session[:login_cooldown] - Time.now).to_i
        set_login_error("Too many failed attempts. Wait #{@cooldown_remaining} seconds.")
      end
      erb :welcome
    end
  end

  post '/welcome' do
    session[:failed_logins] ||= 0
    cooldown_time = 60 

    if session[:login_cooldown] && Time.now < session[:login_cooldown]
      @cooldown_remaining = (session[:login_cooldown] - Time.now).to_i
      set_login_error("Too many failed attempts. Wait #{@cooldown_remaining} seconds.")
      return erb :welcome
    end

    user = User.find_by_username(params[:username])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      session[:failed_logins] = 0
      session.delete(:login_cooldown)
      redirect to(user.role == 'admin' ? '/admin' : "/users/#{user.id}")
    else
      session[:failed_logins] += 1

      if session[:failed_logins] >= 3
        set_login_error("Too many failed attempts. Wait 60 seconds.", cooldown_time)
      else
        set_login_error("Wrong username or password. Attempt #{session[:failed_logins]} of 3.")
      end

      erb :welcome
    end
  end

  post '/logout' do
    session.clear
    redirect to '/'
  end
end