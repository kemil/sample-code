class Backoffice::OptionsController < ApplicationController
  before_action :set_info

  def index
  	if params[:type] == 'agency'
      if current_user.has_role? :admin, current_user.agency
    		@agency_settings = current_user.agency.settings
    		render 'backoffice/options/agency'
      else
        redirect_to '/', :notice => "You don't have permission"
      end
  	elsif params[:type] == 'account'
  		@account_settings = current_user.settings
  		render 'backoffice/options/account'
  	else
  		redirect_to backoffice_path(:type => 'account')
  	end
  end

  def process_account_options
    current_user.settings['notifications.new_lead'] = account_options_params['notifications.new_lead']
    current_user.settings['notifications.new_prospect'] = account_options_params['notifications.new_prospect']
    current_user.save!
    redirect_to backoffice_path(:type => 'account'), notice: 'Account option was successfully updated.'
  end

  def process_agency_options
    current_user.settings['agency.email'] = agency_options_params['agency.email']
    current_user.save!
    redirect_to backoffice_path(:type => 'agency'), notice: 'Agency option was successfully updated.'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Options'
    @page_secondary = 'Customize your experience'
    @page_title = 'LeadAccount | Options'
    @page_icon = 'play-circle'
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_options_params
    params.require(:settings).permit('notifications.new_lead','notifications.new_prospect')
  end

  def agency_options_params
  	params.require(:settings).permit('agency.email')
  end
end
