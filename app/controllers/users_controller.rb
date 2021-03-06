class UsersController < ApplicationController
  before_action :authenticate, except: [:login, :create]

  def apikey
    render json: {key: ENV['GOOGLE_API_KEY']}
  end

  def create
    puts user_params
    user = User.new(user_params)
    if user.save
      token = token(user.id, user.username)
      render json: {status: 200, message: "ok", token: token, user: user}
    else
      render json: {status: 422, user: user, errors: user.errors }
    end
  end

  def show
    user = User.find(params[:id])
    albums = User.find(params[:id]).albums
    render json: {status: 200, user: user, albums: albums}
  end

  def current
    user = current_user
    user = User.find(user[0]['user']['id'])
    if user
      render json: {status: 200, user: user}
    else
      render json: {status: 422, message: "no current user"}
    end
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: {status: 200, user: user}
    else
      render json: {status: 422, user: user}
    end
  end

  def destroy
    User.destroy(params[:id])

    render json: { status: 204 }
  end

  def login
    user = User.find_by(username: params[:user][:username])

      if user && user.authenticate(params[:user][:password])
        token = token(user.id, user.username)
        render json: {status: 201, user: user, token: token}
      else
        render json: {status: 401, message: "unauthorized"}
      end
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

    def user_params
      params.required(:user).permit(:password, :firstname, :lastname, :username)
    end

end
