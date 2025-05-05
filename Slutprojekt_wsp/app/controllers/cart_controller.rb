class CartController < ApplicationController
  before ['/cart', '/cart/*'] do
    require_login
  end

  get '/cart' do
    @cart = current_user.cart || Cart.create_for_user(current_user.id)
    @cart_items = @cart.items
    @total_price = @cart.total_price
    erb :'cart/index'
  end

  post '/cart/add/:id' do
    product = Product.find(params[:id].to_i)
    halt 404, "Item doesn't exist" unless product

    cart = current_user.cart || Cart.create_for_user(current_user.id)
    quantity = (params[:quantity] || 1).to_i
    cart.add_product(product.id, quantity)

    redirect to(request.referer || '/shop')
  end

  post '/cart/remove/:id' do
    if cart = current_user.cart
      cart.remove_product(params[:id].to_i)
    end
    redirect to '/cart'
  end

  post '/cart/checkout' do
    if cart = current_user.cart
      cart.clear
      erb :'cart/checkout'
    else
      redirect to '/cart'
    end
  end
end