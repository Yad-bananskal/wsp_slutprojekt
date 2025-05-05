class Cart
  attr_reader :id, :user_id

  def initialize(attributes)
    @id = attributes['id']
    @user_id = attributes['user_id']
  end

  def self.find_by_user(user_id)
    result = DB.connection.execute('SELECT * FROM carts WHERE user_id = ?', user_id).first
    return nil unless result
    new(result)
  end

  def self.create_for_user(user_id)
    DB.connection.execute('INSERT INTO carts (user_id) VALUES (?)', user_id)
    new({
      'id' => DB.connection.last_insert_row_id,
      'user_id' => user_id
    })
  end

  def items
    DB.connection.execute(
      'SELECT products.*, cart_items.quantity 
       FROM cart_items 
       JOIN products ON cart_items.product_id = products.id 
       WHERE cart_items.cart_id = ?', @id
    ).map do |item|
      {
        product: Product.new(item),
        quantity: item['quantity']
      }
    end
  end

  def total_items
    result = DB.connection.execute(
      'SELECT SUM(quantity) FROM cart_items WHERE cart_id = ?', @id
    ).first
    result.values.first || 0
  end

  def total_price
    items.sum do |item|
      item[:product].price * item[:quantity]
    end
  end

  def add_product(product_id, quantity = 1)
    existing_item = DB.connection.execute(
      'SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?', 
      [@id, product_id]
    ).first

    if existing_item
      DB.connection.execute(
        'UPDATE cart_items SET quantity = quantity + ? WHERE id = ?',
        [quantity, existing_item['id']]
      )
    else
      DB.connection.execute(
        'INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)',
        [@id, product_id, quantity]
      )
    end
  end

  def remove_product(product_id)
    DB.connection.execute(
      'DELETE FROM cart_items WHERE cart_id = ? AND product_id = ?',
      [@id, product_id]
    )
  end

  def clear
    DB.connection.execute('DELETE FROM cart_items WHERE cart_id = ?', @id)
  end
end
