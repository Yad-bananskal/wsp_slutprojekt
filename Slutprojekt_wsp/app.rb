require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'securerandom'

class App < Sinatra::Base
  configure do
    set :public_folder, 'public'
    set :views, 'views'
    set :method_override, true
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  helpers do
    def db
      @db ||= SQLite3::Database.new("db/development.sqlite")
      @db.results_as_hash = true
      @db
    end

    def current_user
      return nil unless logged_in?
      db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
    end

    def logged_in?
      !!session[:user_id]
    end
  end

  get '/' do
    redirect '/welcome'
  end

  #Sign Up
  get '/users/signup' do
    redirect to "/users/#{current_user[:id]}" if logged_in?
    erb :'users/signup'
  end

  post '/users/signup' do
    #Kolla om användarnamnet redan finns
    existing_user = db.execute('SELECT * FROM users WHERE username = ?', [params[:username]]).first
    if existing_user
      @signup_error = "Username already exists, please try again"
      return erb :'users/signup'
    end

    #Hasha lösenordet
    hashed_password = BCrypt::Password.create(params[:password])

    db.execute(
      'INSERT INTO users (username, password_digest) VALUES (?, ?)',
      [params[:username], hashed_password]
    )

    #Ställer in en session och redirectar
    user_id = db.last_insert_row_id
    session[:user_id] = user_id
    redirect to "/users/#{user_id}"
  end

  #Login
  get '/welcome' do
    redirect to "/users/#{current_user[:id]}" if logged_in?
    erb :'welcome'
  end

  post '/welcome' do
    @user = db.execute('SELECT * FROM users WHERE username = ?', params[:username]).first

    if @user && BCrypt::Password.new(@user['password_digest']) == params[:password]
      session[:user_id] = @user['id']
      redirect to "/users/#{@user['id']}"
    else
      @login_error = "Something went wrong! Please try again"
      erb :'welcome'
    end
  end

  #Visa användarvyn
  get '/users/:id' do
    redirect to "/" unless logged_in?

    @user = db.execute('SELECT * FROM users WHERE id = ?', params[:id]).first
    halt(404, "User not found") unless @user

    @tasks = db.execute('SELECT * FROM tasks WHERE user_id = ?', @user['id'])
    erb :'users/show'
  end

  #Logout
  post '/logout' do
    session.clear
    redirect to "/"
  end

  #Ny uppgift/task
  get '/tasks/new' do
    redirect to "/" unless logged_in?

    @user = current_user
    erb :'tasks/new'
  end

  #Create task
  post '/tasks' do
    redirect to "/" unless logged_in?

    @user = current_user

    if params[:description].empty?
      @create_error = "Description can't be empty"
      return erb :'tasks/new'
    end

    db.execute(
      'INSERT INTO tasks (description, due, status, user_id) VALUES (?, ?, ?, ?)',
      [params[:description], params[:due], params[:status], @user['id']]
    )

    redirect to "/users/#{@user['id']}"
  end

  #Show task
  get '/tasks/:id' do
    redirect to "/" unless logged_in?

    @task = db.execute('SELECT * FROM tasks WHERE id = ?', params[:id]).first
    halt(404, "Task not found") unless @task

    erb :'tasks/show'
  end

  #Edit task
  get '/tasks/:id/edit' do
    redirect to "/" unless logged_in?

    @task = db.execute('SELECT * FROM tasks WHERE id = ? AND user_id = ?', [params[:id], current_user['id']]).first
    halt(404, "Task not found") unless @task

    erb :'tasks/edit'
  end

  #Update task
  patch '/tasks/:id' do
    redirect to "/" unless logged_in?

    @task = db.execute('SELECT * FROM tasks WHERE id = ? AND user_id = ?', params[:id], current_user['id']).first
    halt(404, "Task not found") unless @task

    db.execute(
      'UPDATE tasks SET description = ?, due = ?, status = ? WHERE id = ?',
      params[:description], params[:due], params[:status], params[:id]
    )

    redirect to "/users/#{current_user['id']}"
  end

  #Delete task
  delete '/tasks/:id' do
    redirect to "/" unless logged_in?

    @task = db.execute('SELECT * FROM tasks WHERE id = ? AND user_id = ?', params[:id], current_user['id']).first
    halt(404, "Task not found") unless @task

    db.execute('DELETE FROM tasks WHERE id = ?', params[:id])

    redirect to "/users/#{current_user['id']}"
  end
end