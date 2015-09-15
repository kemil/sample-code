class ProspectsController < ApplicationController
  load_and_authorize_resource
  before_action :set_prospect, only: [:show, :edit, :update, :destroy]
  before_action :set_statuses, only: [:new, :edit, :create]
  before_action :prime_prospect, only: [:show, :edit]
  before_action :prime_prospect_note, only: [:show]
  before_action :set_info
  before_action :mark_as_read, only: [:show]

  # GET /prospects
  # GET /prospects.json
  def index
    @prospects = Prospect.all
  end

  # GET /prospects/1
  # GET /prospects/1.json
  def show
    @location = @prospect.locations.new
    @abentry = Abentry.new
  end

  # GET /prospects/new
  def new
    @prospect = Prospect.new
  end

  # GET /prospects/1/edit
  def edit
  end

  def update_counters
    Prospect.counter_culture_fix_counts
    @prospects = Prospect.all
    render action: 'index'
  end

  # POST /prospects
  # POST /prospects.json
  def create
    @prospect = Prospect.new(prospect_params)

    respond_to do |format|
      if @prospect.save
        format.html { redirect_to @prospect, notice: 'Prospect was successfully created.' }
        format.json { render action: 'show', status: :created, location: @prospect }
      else
        format.html { render action: 'new' }
        format.json { render json: @prospect.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prospects/1
  # PATCH/PUT /prospects/1.json
  def update
    respond_to do |format|
      if @prospect.update(prospect_params)
        format.html { redirect_to @prospect, notice: 'Prospect was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @prospect.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prospects/1
  # DELETE /prospects/1.json
  def destroy
    @prospect.destroy
    respond_to do |format|
      format.html { redirect_to prospects_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prospect
      @prospect = Prospect.find(params[:id])
    end

    def set_statuses
      @statuses = Status.where(:statusable_type => 'Prospect')
      @tap_types = Type.where(:typeable_type => 'Tap')
    end

    def prime_prospect
      # Let's disconnect the contacts from the prospect for right now.
      #if @prospect.contacts.empty?
      #  Contact.create(contactable: @prospect, salutation: @prospect.lead.salutation, first_name: @prospect.lead.first_name, middle_name: @prospect.lead.middle_name, last_name: @prospect.lead.last_name, suffix: @prospect.lead.suffix, dob: @prospect.lead.dob, primary: true)
      #end
    end

    def prime_prospect_note
      @note = Note.new()
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def prospect_params
      params.require(:prospect).permit(:first_name, :last_name, :middle_name, :salutation, :lead_id, :prospectable_id, :prospectable_type, :status_id)
    end

    def set_info
      @page_header = 'Prospect'
      @page_title = 'LeadAccount | Prospect'
      @page_class = 'Prospect'
      @page_icon = 'fire'
    end

    def mark_as_read
      if @prospect.prospectable == current_user
        @prospect.mark_as_read! :for => current_user
      end
    end
end
