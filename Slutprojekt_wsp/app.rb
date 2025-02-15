require 'sinatra'
require 'securerandom'
require 'bcrypt'
require 'sqlite3'

class App < Sinatra::Base

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  def db
    @db ||= SQLite3::Database.new("db/users.sqlite")
    @db.results_as_hash = true
    @db
  end

  get '/' do
    if session[:user_id]
      redirect '/admin'
    else
      erb :index
    end
  end

  post '/register' do
    username = params[:username]
    plain_password = params[:password]

    if username.empty? || plain_password.empty?
      status 400
      return "Username and password cannot be empty."
    end

    hashed_password = BCrypt::Password.create(plain_password)
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', [username, hashed_password])
    redirect '/login'
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    username = params[:username]
    plain_password = params[:password]

    user = db.execute('SELECT * FROM users WHERE username = ?', [username]).first

    if user && BCrypt::Password.new(user['password']) == plain_password
      session[:user_id] = user['id']
      redirect '/admin'
    else
      status 401
      "Invalid username or password"
    end
  end

  get '/admin' do
    if session[:user_id]
      erb :admin
    else
      redirect '/unauthorized'
    end
  end

  get '/unauthorized' do
    erb :unauthorized
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/users' do
    @users = User.all # This fetches all users from the database
    erb :index # Render the index.erb view
  end
  
end
