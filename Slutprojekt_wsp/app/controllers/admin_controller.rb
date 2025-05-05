require_relative 'application_controller'
require_relative '../models/product'
require_relative '../models/category'

class AdminController < ApplicationController
  before do
    require_admin
    @current_user = current_user
  end

  get '/admin' do
    @products = Product.all
    erb :'admin/index'
  end

  get '/admin/products/new' do
    @categories = Category.all
    erb :'admin/new'
  end

  post '/admin/products' do
    if params[:name].to_s.empty? || params[:price].to_s.empty? || params[:category_id].to_s.empty?
      @categories = Category.all
      @error = "Namn, pris och kategori krävs"
      return erb :'admin/new'
    end

    Product.create(
      name: params[:name],
      description: params[:description],
      price: params[:price].to_f,
      stock: params[:stock].to_i,
      category_id: params[:category_id].to_i
    )
    redirect to('/admin')
  end

  get '/admin/products/:id/edit' do
    @product = Product.find(params[:id])
    @categories = Category.all
    erb :'admin/edit'
  end

  patch '/admin/products/:id' do
    product = Product.find(params[:id])
    product.update(
      name: params[:name],
      description: params[:description],
      price: params[:price].to_f,
      stock: params[:stock].to_i,
      category_id: params[:category_id].to_i
    )
    redirect to('/admin')
  end

  delete '/admin/products/:id' do
    Product.find(params[:id])&.destroy
    redirect to('/admin')
  end
end