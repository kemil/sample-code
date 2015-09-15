class AbentriesController < ApplicationController
  before_action :set_abentry, only: [:show, :edit, :update, :destroy]

  # GET /abentries
  # GET /abentries.json
  def index
    @abentries = Abentry.all
  end

  # GET /abentries/1
  # GET /abentries/1.json
  def show
  end

  # GET /abentries/new
  def new
    @abentry = Abentry.new
  end

  # GET /abentries/1/edit
  def edit
  end

  # POST /abentries
  # POST /abentries.json
  def create
    @abentry = Abentry.new(abentry_params)
    @prospect = Prospect.find(@abentry.abentryable_id)
    respond_to do |format|
      if @abentry.save
        @message = 'Address book was successfully created.'
        @abentry = Abentry.new
      end
      format.js
    end
  end

  # PATCH/PUT /abentries/1
  # PATCH/PUT /abentries/1.json
  def update
    respond_to do |format|
      if @abentry.update(abentry_params)
        format.html { redirect_to @abentry, notice: 'Address book was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @abentry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /abentries/1
  # DELETE /abentries/1.json
  def destroy
    @abentry.destroy
    respond_to do |format|
      format.html { redirect_to abentries_url, notice: 'Address book was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_abentry
      @abentry = Abentry.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def abentry_params
      params.require(:abentry).permit(:abentryable_id, :abentryable_type, :abparam, :primary, :type_id)
    end
end
