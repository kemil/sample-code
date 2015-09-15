class ContactsController < ApplicationController
  load_and_authorize_resource :except => [:create]
  before_action :set_contact, only: [:show, :edit, :update, :destroy]
  before_action :prime_contact_note
  before_action :set_return_to
  before_action :set_info

  # GET /contacts
  # GET /contacts.json
  def index
    @contacts = Contact.all
  end

  # GET /contacts/1
  # GET /contacts/1.json
  def show
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts
  # POST /contacts.json
  def create
    @contact = Contact.new(contact_params)

    respond_to do |format|
      if @contact.save
        format.html { redirect_to prospect_path(@contact.contactable) }
        format.json { render action: 'show', status: :created, location: @contact }
      else
        format.html { redirect_to session.delete(:return_to) }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contacts/1
  # PATCH/PUT /contacts/1.json
  def update
    respond_to do |format|
      if @contact.update(contact_params)
        format.html { redirect_to @contact, notice: 'Contact was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1
  # DELETE /contacts/1.json
  def destroy
    if @contact.contactable.contacts.size > 1
      @contact.destroy
    else
      flash[:notice] = 'You are not allowed to delete the only remaining contact';
    end
    respond_to do |format|
      format.html { redirect_to session.delete(:return_to) }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.require(:contact).permit(:first_name, :middle_name, :last_name, :dob,
                                    :type_id, :contactable_id, :contactable_type,
                                    locations_attributes: [:address_one, :address_two,
                                                           :city, :state, :county, :zip_code,
                                                           :zip_ext, :longitude, :latitude])
  end

  def prime_contact_note
    @note = Note.new()
  end

  def set_return_to
    session[:return_to] ||= request.referer
  end

  def set_info
    @page_header = 'Contact'
    @page_title = 'LeadAccount | Contact'
    @page_class = 'Contact'
  end
end
