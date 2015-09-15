class Backoffice::PipesController < ApplicationController
  before_filter :new_pipe, :only => [:new, :create]
  load_and_authorize_resource
  before_action :set_pipe, only: [:show, :edit, :update, :destroy]
  before_action :set_info
  before_filter :check_if_keycode_already_used, only: [:create]

  # GET /pipes
  # GET /pipes.json
  def index
    @pipes = Pipe.all
  end

  # GET /pipes/1
  # GET /pipes/1.json
  def show
  end

  # GET /pipes/new
  def new
    @pipe = Pipe.new
  end

  # GET /pipes/1/edit
  def edit
  end

  # POST /pipes
  # POST /pipes.json
  def create

    respond_to do |format|
      if @pipe.save
        format.html { redirect_to backoffice_pipes_url, notice: 'Pipe was successfully created.' }
        format.json { render action: 'show', status: :created, location: @pipe }
      else
        format.html { render action: 'new' }
        format.json { render json: @pipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pipes/1
  # PATCH/PUT /pipes/1.json
  def update
    respond_to do |format|
      if @pipe.update(pipe_params)

        format.html { redirect_to backoffice_pipes_url, notice: 'pipe was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @pipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pipes/1
  # DELETE /pipes/1.json
  def destroy
    @pipe.destroy
    respond_to do |format|
      format.html { redirect_to backoffice_pipes_url, notice: 'pipe was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_pipe
      @pipe = Pipe.find(params[:id])
    end

    def new_pipe
      @pipe = current_user.agency.pipes.new(pipe_params)
      @pipe.pipeable_type = 'User'
      @pipe.type_id = 39
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pipe_params
      params.require(:pipe).permit(:pipeable_id, :filter_param)
    end

    def set_info
      @page_header = 'Pipes'
      @page_title = 'LeadAccount | Pipes'
      @page_class = 'Pipe'
      @page_icon = 'code-fork'
    end

    def check_if_keycode_already_used
      if Pipe.exists?(:agency => current_user.agency, :filter_param => pipe_params[:filter_param])
        redirect_to backoffice_pipes_url, flash: { notice: 'That keycode is already used in a pipe.' }
      end
    end
end
