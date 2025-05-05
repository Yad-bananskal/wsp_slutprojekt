class Category
  attr_reader :id, :name

  def initialize(attributes)
    @id = attributes['id']
    @name = attributes['name']
  end

  def self.all
    DB.connection.execute('SELECT * FROM categories').map do |c|
      new(c)
    end
  end

  def self.find(id)
    result = DB.connection.execute(
      'SELECT * FROM categories WHERE id = ?', id
    ).first
    new(result) if result
  end

  def products
    DB.connection.execute(
      'SELECT * FROM products WHERE category_id = ?', @id
    ).map { |p| Product.new(p) }
  end
end
