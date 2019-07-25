class UsersController < ApplicationController

  def index
  end

  def create 
    @user = User.new(user_params)
    if @user.save 
      session[:user_id] = @user.id
      flash[:success] = 'Your account has been created!'
      redirect_to '/'
    else
      flash[:warning] = 'Invalid email or password, please try again.'
      redirect_to '/'
    end
  end

  def update
  end

  private

  def user_params
    params.require(:users).permit(:name, :email, :phone, :topic, :password)
  end

end
