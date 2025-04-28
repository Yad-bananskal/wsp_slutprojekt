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

    db = SQLite3::Database.new("db/development.sqlite")
    begin
      db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'")
    rescue SQLite3::SQLException => e
    end
  end

  helpers do
    def db_conn
      @db_conn ||= begin
        db = SQLite3::Database.new("db/development.sqlite")
        db.results_as_hash = true
        db
      end
    end

    def current_user
      return unless session[:user_id]
      db_conn.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
    end

    def logged_in?
      !!session[:user_id]
    end

    def admin_user?
      logged_in? && current_user['role'] == 'admin'
    end

    def total_cart_items
      return 0 unless logged_in?
      
      cart = db_conn.execute('SELECT id FROM carts WHERE user_id = ?', [current_user['id']]).first
      return 0 unless cart
      
      count = db_conn.execute('SELECT SUM(quantity) FROM cart_items WHERE cart_id = ?', [cart['id']]).dig(0, 0)
      count ||= 0
    end
  end

  get '/' do
    redirect to '/shop'
  end

  get '/unauthorized' do
    erb :unauthorized
  end

  get '/users/signup' do
    redirect to "/users/#{current_user['id']}" if logged_in?
    erb :'users/signup'
  end

  post '/users/signup' do
    if params[:username].to_s.strip.empty? || params[:password].to_s.strip.empty?
      @signup_error = "Don't leave username or password blank!"
      return erb :'users/signup'
    end

    existing_user = db_conn.execute('SELECT * FROM users WHERE username = ?', params[:username]).first
    if existing_user
      @signup_error = "That username is taken. Try again."
      return erb :'users/signup'
    end

    #skapa ny användare
    pw_digest = BCrypt::Password.create(params[:password])
    db_conn.execute('INSERT INTO users (username, password_digest, role) VALUES (?, ?, ?)', [params[:username], pw_digest, 'user'])
    session[:user_id] = db_conn.last_insert_row_id

    redirect to "/users/#{session[:user_id]}"
  end

  get '/welcome' do
    if logged_in?
      dest = admin_user? ? '/admin' : "/users/#{current_user['id']}"
      redirect to dest
    else
      if session[:login_cooldown] && Time.now < session[:login_cooldown]
        @cooldown_remaining = (session[:login_cooldown] - Time.now).to_i
        @login_error = "För många misslyckade försök. Vänta #{@cooldown_remaining} sekunder."
      end
      erb :welcome
    end
  end
  

  post '/welcome' do
    session[:failed_logins] ||= 0
    cooldown_time = 60 # seconds
  
    # Check if cooldown is active
    if session[:login_cooldown] && Time.now < session[:login_cooldown]
      @cooldown_remaining = (session[:login_cooldown] - Time.now).to_i
      @login_error = "För många misslyckade försök. Vänta #{@cooldown_remaining} sekunder."
      return erb :welcome
    end
  
    user = db_conn.execute('SELECT * FROM users WHERE username = ?', params[:username]).first
  
    if user && BCrypt::Password.new(user['password_digest']) == params[:password]
      session[:user_id] = user['id']
      session[:failed_logins] = 0
      session.delete(:login_cooldown)
      redirect to(user['role'] == 'admin' ? '/admin' : "/users/#{user['id']}")
    else
      session[:failed_logins] += 1
  
      if session[:failed_logins] >= 3
        session[:login_cooldown] = Time.now + cooldown_time
        @cooldown_remaining = cooldown_time
        @login_error = "För många misslyckade försök. Vänta #{@cooldown_remaining} sekunder."
      else
        @login_error = "Fel användarnamn eller lösenord. Försök #{session[:failed_logins]} av 3."
      end
  
      erb :welcome
    end
  end
  

  #utloggnig routes
  post '/logout' do
    session.clear
    redirect to '/'
  end

  #webbshop
  get '/shop' do
    @products = db_conn.execute('SELECT * FROM products')
    erb :'shop/index'
  end

  get '/shop/:id' do
    @product = db_conn.execute('SELECT * FROM products WHERE id = ?', params[:id]).first
    halt 404, "Whoops, product not found" unless @product
    erb :'shop/show'
  end

  #kundvagn
  get '/cart' do
    redirect to '/welcome' unless logged_in?

    user_cart = db_conn.execute('SELECT id FROM carts WHERE user_id = ?', current_user['id']).dig(0, 'id')
    
    if user_cart
      @cart_items = db_conn.execute(<<-SQL, user_cart)
        SELECT products.id, products.name, products.price, cart_items.quantity
        FROM cart_items
        JOIN products ON cart_items.product_id = products.id
        WHERE cart_items.cart_id = ?
      SQL
      
      @total_price = @cart_items.map { |item| item['price'] * item['quantity'] }.sum
    else
      @cart_items = []
      @total_price = 0
    end

    erb :'cart/index'
  end

  post '/cart/add/:id' do
    redirect to '/welcome' unless logged_in?

    item_id = params[:id].to_i
    qty = (params[:quantity] || 1).to_i

    product = db_conn.execute('SELECT * FROM products WHERE id = ?', item_id).first
    halt 404, "Item doesn't exist" unless product

    user_cart = db_conn.execute('SELECT * FROM carts WHERE user_id = ?', current_user['id']).first

    if user_cart.nil?
      db_conn.execute('INSERT INTO carts (user_id) VALUES (?)', [current_user['id']])
      cart_id = db_conn.last_insert_row_id
    else
      cart_id = user_cart['id']
    end

    already_in_cart = db_conn.execute('SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?', [cart_id, item_id]).first

    if already_in_cart
      db_conn.execute('UPDATE cart_items SET quantity = quantity + ? WHERE id = ?', [qty, already_in_cart['id']])
    else
      db_conn.execute('INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)', [cart_id, item_id, qty])
    end

    redirect to(request.referer || '/shop')
  end

  post '/cart/remove/:id' do
    redirect to '/welcome' unless logged_in?

    user_cart = db_conn.execute('SELECT id FROM carts WHERE user_id = ?', current_user['id']).first

    if user_cart
      db_conn.execute('DELETE FROM cart_items WHERE cart_id = ? AND product_id = ?', [user_cart['id'], params[:id].to_i])
    end

    redirect to '/cart'
  end

  post '/cart/checkout' do
    redirect to '/welcome' unless logged_in?

    cart_id = db_conn.execute('SELECT id FROM carts WHERE user_id = ?', current_user['id']).dig(0, 'id')
    if cart_id
      db_conn.execute('DELETE FROM cart_items WHERE cart_id = ?', [cart_id])
      erb :'cart/checkout'
    else
      redirect to '/cart'
    end
  end

  #Admin panel 
  get '/admin' do
    redirect to '/unauthorized' unless admin_user?
    @current_user = current_user
    @products = db_conn.execute('SELECT * FROM products')
    erb :'admin/index'
  end

  get '/admin/products/new' do
    redirect to '/unauthorized' unless admin_user?
    @categories = db_conn.execute('SELECT * FROM categories')
    erb :'admin/new'
  end

  post '/admin/products' do
    redirect to '/unauthorized' unless admin_user?

    missing_fields = [:name, :price, :category_id].select { |field| params[field].to_s.strip.empty? }
    halt 400, "Missing: #{missing_fields.join(', ')}" unless missing_fields.empty?

    db_conn.execute('INSERT INTO products (name, description, price, stock, category_id) VALUES (?, ?, ?, ?, ?)',
                    [params[:name], params[:description], params[:price].to_f, params[:stock].to_i, params[:category_id].to_i])

    redirect to '/admin'
  end

  get '/admin/products/:id/edit' do
    redirect to '/unauthorized' unless admin_user?
    @product = db_conn.execute('SELECT * FROM products WHERE id = ?', params[:id]).first
    halt 404, "Can't find that product" unless @product
    @categories = db_conn.execute('SELECT * FROM categories')
    erb :'admin/edit'
  end

  patch '/admin/products/:id' do
    redirect to '/unauthorized' unless admin_user?

    db_conn.execute('UPDATE products SET name = ?, description = ?, price = ?, stock = ?, category_id = ? WHERE id = ?',
                    [params[:name], params[:description], params[:price].to_f, params[:stock].to_i, params[:category_id].to_i, params[:id].to_i])

    redirect to '/admin'
  end

  delete '/admin/products/:id' do
    redirect to '/unauthorized' unless admin_user?

    db_conn.execute('DELETE FROM products WHERE id = ?', params[:id].to_i)
    redirect to '/admin'
  end

  get '/users/:id' do
    redirect to '/' unless logged_in?

    @user = db_conn.execute('SELECT * FROM users WHERE id = ?', params[:id]).first
    halt 404, "Couldn't find the user" unless @user

    erb :'users/show'
  end
end
