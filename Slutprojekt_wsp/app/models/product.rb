class Product
  attr_reader :id, :name, :description, :price, :stock, :category_id

  def initialize(attributes)
    @id = attributes['id']
    @name = attributes['name']
    @description = attributes['description']
    @price = attributes['price']
    @stock = attributes['stock'] || 0
    @category_id = attributes['category_id']
  end

  def self.all
    DB.connection.execute('SELECT * FROM products').map { |row| new(row) }
  end

  def self.find(id)
    result = DB.connection.execute('SELECT * FROM products WHERE id = ?', id).first
    new(result) if result
  end

  def self.find_by_category(category_id)
    DB.connection.execute(
      'SELECT * FROM products WHERE category_id = ?', category_id
    ).map { |p| new(p) }
  end

  def self.create(name:, description:, price:, stock: 0, category_id:)
    DB.connection.execute(
      'INSERT INTO products (name, description, price, stock, category_id) VALUES (?, ?, ?, ?, ?)',
      [name, description, price, stock, category_id]
    )

    new({
      'id' => DB.connection.last_insert_row_id,
      'name' => name,
      'description' => description,
      'price' => price,
      'stock' => stock,
      'category_id' => category_id
    })
  end

  def update(name:, description:, price:, stock:, category_id:)
    # Could be nice to compare old vs new and only update changed fields?
    DB.connection.execute(
      'UPDATE products SET name = ?, description = ?, price = ?, stock = ?, category_id = ? WHERE id = ?',
      [name, description, price, stock, category_id, @id]
    )
  end

  def destroy
    DB.connection.execute('DELETE FROM products WHERE id = ?', @id)
  end

  def category
    Category.find(@category_id)
  end

  def in_stock?
    @stock > 0
  end

  def out_of_stock?
    @stock <= 0
  end
end
