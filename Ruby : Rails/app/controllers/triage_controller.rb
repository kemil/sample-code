class TriageController < ApplicationController
  before_action :set_info
  before_action :authorize
  respond_to :html, :js , :only => :get_leads

  def index
    @leads = "first_load"
  end

  def get_leads
    make_persistent_option


    if !@sort_by.blank? && !@sort_in.blank?
      leads = current_user.agency.leads.orphaned.order("#{@sort_by} #{@sort_in}")
    else
      leads = current_user.agency.leads.orphaned
    end

    if params[:key].blank? || params[:key] == 'blank'
      objs = leads
    else
      conditions = "leads.keycode ILIKE '%#{params[:key]}%' OR leads.first_name ILIKE '%#{params[:key]}%' OR leads.last_name ILIKE '%#{params[:key]}%' OR cast(leads.zip_code as text) ILIKE '%#{params[:key]}%' OR leads.county ILIKE '%#{params[:key]}%' OR cast(leads.returned_date as text) ILIKE '%#{params[:key]}%' OR leads.order_no ILIKE '%#{params[:key]}%'"
      objs = leads.where(conditions)
    end
    per_page = @per_page == '-1' ? objs.length : @per_page
    @leads = objs.page(@page).per(per_page)

    if params[:page].blank? && params[:per_page].blank? && params[:key].blank? && params[:sort_in].blank? && params[:sort_by].blank?
      render :partial => 'widgets/modules/leads/table', :locals => {from: 'triage'}, content_type: 'text/html'
    end
  end

  def process_multiple
    @leads = Lead.find(lead_params[:lead_ids])

    i = 0
    user_target = User.find(lead_params[:target_user_id])
    @leads.each do |lead|
      type_id = Prospect.manual_type
      pros = Prospect.find_or_create_by( lead: lead, prospectable: user_target, type_id: type_id )
      pros.update_attributes(:first_name => lead.first_name,
                             :last_name => lead.last_name,
                             :middle_name => lead.middle_name,
                             :salutation => lead.salutation,
                             :status_id => 19)
      i += 1
    end

    #send email notifier base on target options
    if user_target.settings["notifications.new_prospect"] == "1"
      Notifier.new_prospect(user_target, i, current_user.email).deliver
    end

    respond_to do |format|
      format.html { redirect_to triage_index_path, notice: 'Leads was successfully assigned.' }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Triage'
    @page_secondary = 'Your leads are hot. Distribute some prospects now!'
    @page_title = 'LeadAccount | Triage'
    @page_icon = 'play-circle'
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def lead_params
    params.require(:lead).permit(:target_user_id, :lead_ids => [])
  end

  def authorize
    authorize! :manage, current_user.agency
  end
end
