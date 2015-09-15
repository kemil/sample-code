class Backoffice::GroupsController < ApplicationController
  before_filter :new_group, :only => [:new, :create]
  load_and_authorize_resource
  before_action :set_group, only: [:show, :edit, :update, :destroy]
  before_action :set_info

  # GET /groups
  # GET /groups.json
  def index
    @groups = current_user.agency.groups

  end

  # GET /groups/1
  # GET /groups/1.json
  def show
  end

  # GET /groups/new
  def new
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = current_user.agency.groups.new(group_params)

    respond_to do |format|
      if @group.save
        format.html { redirect_to backoffice_groups_url, notice: 'Group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @group }
      else
        format.html { render action: 'new' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  def update
    respond_to do |format|
      if @group.update(group_params)
        format.html { redirect_to [:backoffice, @group], notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to backoffice_groups_url, notice: 'Group was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def group_params
      params.require(:group).permit(:parent_id, :name, :user_ids => [])
    end

    def new_group
      @group = Group.new(group_params)
    end

    def set_info
      @page_header = 'Group Management'
      @page_title = 'LeadAccount | Backoffice | Groups'
      @page_icon = 'group'
    end
end
