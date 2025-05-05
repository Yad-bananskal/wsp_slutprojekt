require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'securerandom'

require_relative './config/database'

Dir[File.join(__dir__, 'app', 'models', '*.rb')].sort.each { |file| require file }

Dir[File.join(__dir__, 'app', 'controllers', '*.rb')].sort.each { |file| require file }

class App < Sinatra::Base
  configure do
    set :public_folder, File.join(__dir__, 'public')
    set :views, File.join(__dir__, 'views')
    set :method_override, true
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  use UsersController
  use ShopController
  use CartController
  use AdminController

  run! if app_file == $0
end