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
    if current_user
      @user = User.find_by(email: params[:user][:email])
      @user.update(user_params)
      @user.save
    else
      flash[:warning] = 'You must be logged in to update your settings.'
      redirect_to '/'
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :phone, :topic, :password)
  end

end
