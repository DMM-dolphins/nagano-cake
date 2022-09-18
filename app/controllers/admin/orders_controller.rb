class Admin::OrdersController < ApplicationController

  def show
    @order = Order.find(params[:id])
    @total_price = 0
    @order_details.each do |order_detail|
      @total_price += order_detail.item.add_tax_price*order_detail.item.amount
    end
    @shipping_cost = 800
  end

  def update
    @order = Order.find(params[:id])
    @order_details = @order.order_details
    if @order.update(order_params)
      if @order.status == "confirm_payment"
        @order.order_details.each do |order_detail|
          order_detail.update(status: "wating_manufacture")
        end
      end
      redirect_to admin_order_path(@order.id)
    else
      render "show"
    end
  end

  private

  def order_params
    params.require(:order).permit(:status)
  end


end
