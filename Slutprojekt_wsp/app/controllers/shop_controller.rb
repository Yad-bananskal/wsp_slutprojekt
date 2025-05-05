require_relative 'application_controller'
require_relative '../models/product'

class ShopController < ApplicationController
  get '/shop' do
    @products = Product.all
    erb :'shop/index'
  end

  get '/shop/:id' do
    @product = Product.find(params[:id])
    halt 404, "Whoops, product not found" unless @product
    erb :'shop/show'
  end
end