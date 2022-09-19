class Public::OrdersController < ApplicationController
  before_action :set_shipping_cost, only: [:confirm, :create]

  def new
    @order = Order.new
    @addresses = Address.where(customer_id: current_customer.id)
  end

  def thanks
  end

  def index
    @orders = Order.where(customer_id: current_customer.id)
  end

  def show
    @order = Order.find(params[:id])
  end

  def confirm
    @order = Order.new(order_params)
    @cart_items = CartItem.where(customer_id: current_customer.id)

    session[:customer_id] = current_customer.id
    session[:payment_method] = order_params[:payment_method]

    # 商品合計計算
    session[:sum_price] = 0
    @cart_items.each do |cart_item|
      session[:sum_price] += cart_item.item.with_tax_price*cart_item.amount
    end

    # ラジオボタンの選択によって配送先を表示
    case params[:order][:selected_address]
    when "1" then # ご自身の住所
      session[:postal_code] = current_customer.postal_code
      session[:address] = current_customer.address
      session[:name] = current_customer.full_name
    when "2" then # 登録された住所を選択
      @address = Address.find(params[:order][:address_id])
      session[:postal_code] = @address.postal_code
      session[:address] = @address.address
      session[:name] = @address.name
    when "3" then # 新しいお届け先
      session[:postal_code] = order_params[:postal_code]
      session[:address] = order_params[:address]
      session[:name] = order_params[:name]
    end
  end

  def create
    # 注文テーブルにデータを保存
    @order = Order.new(
      customer_id: session[:customer_id],
      postal_code: session[:postal_code],
      address: session[:address],
      name: session[:name],
      shipping_cost: @shipping_cost,
      total_payment: session[:sum_price] + @shipping_cost,
      payment_method: session[:payment_method]
      )
    @order.save
    
    @order.customer.cart_items.each do |cart_item|
      @order_detail = OrderDetail.new(
        order_id: @order.id,
        item_id: cart_item.item.id,
        price: cart_item.item.with_tax_price,
        amount: cart_item.amount
        )
        @order_detail.save
    end
    @order.customer.cart_items.destroy_all
    redirect_to thanks_path
  end


  private

  def set_shipping_cost
    @shipping_cost = 800
  end

  def order_params
    params.require(:order).permit(:payment_method, :postal_code, :address, :name)
  end

end
