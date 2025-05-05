class CartItem
  attr_reader :id, :cart_id, :product_id, :quantity

  def initialize(attributes)
    @id = attributes['id']
    @cart_id = attributes['cart_id']
    @product_id = attributes['product_id']
    @quantity = attributes['quantity'] || 1
  end

  def self.find(id)
    result = DB.connection.execute(
      'SELECT * FROM cart_items WHERE id = ?', id
    ).first

    return nil unless result  #kanske inte helt nödvändig, kolla senare
    new(result)
  end

  def self.find_by(cart_id:, product_id:)
    result = DB.connection.execute(
      'SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?',
      [cart_id, product_id]
    ).first

    result ? new(result) : nil  #om det nya resultaten är nil
  end

  def self.create(cart_id:, product_id:, quantity: 1)
    DB.connection.execute(
      'INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)',
      [cart_id, product_id, quantity]
    )

    inserted_id = DB.connection.last_insert_row_id
    new(
      'id' => inserted_id,
      'cart_id' => cart_id,
      'product_id' => product_id,
      'quantity' => quantity
    )
  end

  def product
    @product ||= Product.find(@product_id)
  end

  def update(quantity:)
    DB.connection.execute(
      'UPDATE cart_items SET quantity = ? WHERE id = ?',
      [quantity, @id]
    )
    @quantity = quantity
  end

  # Note: Might need to rethink if amount should ever be 0 or negative
  def addition(amount = 1)
    update(quantity: @quantity + amount)
  end

  def subtraction(amount = 1)
    new_quantity = [@quantity - amount, 1].max
    update(quantity: new_quantity)
  end

  def destroy
    DB.connection.execute('DELETE FROM cart_items WHERE id = ?', @id)
  end

  def subtotal
    product.price * @quantity
  end
end
