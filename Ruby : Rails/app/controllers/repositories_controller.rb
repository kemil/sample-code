class RepositoriesController < ApplicationController
  before_action :authorize
  before_action :set_info

  def index
    @leads = 'first_load'
  end

  def get_leads
    make_persistent_option

    if params[:repository_id] == 'filtered'
      objs = current_user.agency.leads.filtered(@sort_by, @sort_in, nil, params[:key]).flatten
    else
      if params[:filter].blank?
        if !@sort_by.blank? && !@sort_in.blank?

          leads = current_user.agency.leads.order("#{@sort_by} #{@sort_in}")
        else

          leads = current_user.agency.leads
        end

        if params[:key].blank? || params[:key] == 'blank'
          objs = leads
        else
          conditions = "leads.keycode ILIKE '%#{params[:key]}%' OR leads.first_name ILIKE '%#{params[:key]}%' OR leads.last_name ILIKE '%#{params[:key]}%' OR cast(leads.zip_code as text) ILIKE '%#{params[:key]}%' OR leads.county ILIKE '%#{params[:key]}%' OR cast(leads.returned_date as text) ILIKE '%#{params[:key]}%' OR leads.order_no ILIKE '%#{params[:key]}%'"
          objs = leads.where(conditions)
        end
      else
        objs = current_user.agency.leads.filtered(@sort_by, @sort_in, params[:filter], params[:key]).flatten
      end
    end

    if objs.kind_of? Array
      per_page = @per_page == '-1' ? objs.length : @per_page
      @leads = Kaminari.paginate_array(objs).page(@page).per(per_page)
    else
      per_page = @per_page == '-1' ? objs.length : @per_page
      @leads = objs.page(@page).per(per_page)
    end

    if params[:page].nil? && params[:per_page].nil? && params[:key].nil? && params[:sort_in].nil? && params[:sort_by].nil? && params[:filter].nil?
      render :partial => 'widgets/modules/leads/table', :locals => {from: 'repository'}, content_type: 'text/html'
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
      format.html { redirect_to  repositories_path, notice: 'Leads was successfully assigned.' }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Repository'
    @page_secondary = ''
    @page_title = 'LeadAccount | Repository'
    @page_icon = 'hdd'
  end

  def lead_params
    params.require(:lead).permit(:target_user_id, :lead_ids => [])
  end

  def authorize
    authorize! :manage, current_user.agency
  end
end
