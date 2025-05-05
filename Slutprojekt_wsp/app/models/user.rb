class User
  attr_reader :id, :username, :role

  def initialize(attributes)
    @id = attributes['id']
    @username = attributes['username']
    @role = attributes['role'] || 'user' 
  end

  def self.find(id)
    result = DB.connection.execute(
      'SELECT * FROM users WHERE id = ?', id
    ).first
    new(result) if result
  end

  def self.find_by_username(username)
    result = DB.connection.execute(
      'SELECT * FROM users WHERE username = ?', username
    ).first
    new(result) if result
  end

  def self.create(username, password, role = 'user')
    pw_digest = BCrypt::Password.create(password)
    DB.connection.execute(
      'INSERT INTO users (username, password_digest, role) VALUES (?, ?, ?)',
      [username, pw_digest, role]
    )
    new({
      'id' => DB.connection.last_insert_row_id,
      'username' => username,
      'role' => role
    })
  end

  def cart
    Cart.find_by_user(@id)
  end

  def cart_total_items
    cart ? cart.total_items : 0
  end

  def authenticate(password)
    user_data = DB.connection.execute(
      'SELECT password_digest FROM users WHERE id = ?', @id
    ).first

    return false unless user_data  #nödvändig??
    BCrypt::Password.new(user_data['password_digest']) == password
  end

  def admin?
    @role == 'admin'
  end
end
