class Backoffice::UsersController < ApplicationController
  before_filter :new_user, :only => [:new, :create]
  load_and_authorize_resource
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_info
  # include GroupsHelper

  # GET /users
  # GET /users.json
  def index
    @users = current_user.agency.users.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    respond_to do |format|
      if @user.save
        Notifier.new_user(@user.email, user_params[:password], @user.agency.name).deliver
        # @user.send_reset_password_instructions
        format.html { redirect_to backoffice_users_url, notice: 'User was successfully created.' }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { render action: 'edit', notice: 'User was successfully updated.' }
        #format.html { redirect_to backoffice_users_url, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to backoffice_users_url, notice: 'User was successfully removed.' }
      format.json { head :no_content }
    end
  end

  def generate_new_password_email
    user = User.find_by_email(params[:email])
    user.send_reset_password_instructions
    flash[:notice] = "Reset password instructions have been sent to #{user.email}"
    redirect_to action: "index"
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

  def new_user
    @user = current_user.agency.users.new(user_params)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password, :avatar, :group_ids => [])
  end

  def set_info
    @page_header = 'User Management'
    @page_title = 'LeadAccount | Backoffice | Users'
    @page_icon = 'group'
  end
end
