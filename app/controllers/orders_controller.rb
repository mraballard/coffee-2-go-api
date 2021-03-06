class OrdersController < ApplicationController
  before_action :authenticate

  def index
    orders = User.find(params[:user_id]).orders.order('orders.created_at DESC').limit('6')
    array = []
    if orders.length > 0
      orders.each do |order|
        array.push({order: order, store: order.store})
      end
      render json: {status: 200, orders: array}
    else
      render json: {status: 422, message: "No orders"}
    end
  end

  def create
    order = Order.new(order_params)
    if order.save
      params[:items].each do |item|
        thisItem = Item.find(item[:product][:id])
        order.items.push(thisItem)
        Detail.create(quantity: item[:quantity], subtotal: item[:subtotal], order_id: order[:id], item_id: thisItem[:id])
      end
      render json: {status: 200, message: "ok", order: order}
    else
      render json: {status: 422, message: "Order not saved", errors: order.errors}
    end
  end

  def show
    orderDetails = []
    orderItems = Order.find(params[:id]).items
    orderItems.each_with_index do |item, index|
      details = Detail.where(order_id: params[:id], item_id: item[:id])
      orderDetails[index] = {item: item, details: details}
      puts details
    end
    if orderDetails.length > 0
      render json: {status: 200, message: "Ok", items: orderDetails}
    else
      render json: {status: 422, message: "No items found"}
    end
  end

  def update

  end

  def destroy
    Order.destroy(params[:id])

    render json: { status: 204 }
  end

  private

    def token(id, username)
      JWT.encode(payload(id, username), ENV['JWT_SECRET'], 'HS256')
    end

    def payload(id, username)
      {
        exp: (Time.now + 1.day).to_i, # Expiration date 24 hours from now
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        user: {
          id: id,
          username: username
        }
      }
    end

    def order_params
      params.required(:order).permit(:total, :user_id, :store_id, :items)
    end

end
