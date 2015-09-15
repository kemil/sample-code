class InsightController < ApplicationController
  before_action :authorize
  before_action :set_info

  def index
    redirect_to :controller => 'insight', :action => 'agents'
  end

  def agents
    if params.has_key? :id
      @agent = User.find(params[:id])
      @prospects = 'first_load'
      render 'insight/agents_show'
    else
      @agents =  gather_agents
    end
  end

  def get_agents
    @agent = User.find(params[:id])
    make_persistent_option

    @key = (params[:key].blank? || params[:key] == 'blank') ? nil : params[:key]
    objs = @agent.sort_active_prospects(@sort_by, @sort_in, nil, nil, nil, nil, nil, nil, @key)
    per_page = @per_page == '-1' ? objs.length : @per_page
    @prospects = Kaminari.paginate_array(objs).page(@page).per(per_page)

    if params[:page].blank? && params[:per_page].blank? && params[:key].blank? && params[:sort_in].blank? && params[:sort_by].blank?
      render :partial => 'widgets/modules/prospects/table_dynamic',  content_type: 'text/html', :locals => {page_type: 'insight'}
    end
  end

  def active_prospect
    @prospect = Prospect.find(params[:id])
    if params[:archive] == 'false'
      @prospect.update_attribute(:archived, false)
    elsif params[:archive] == 'true'
      @prospect.update_attribute(:archived, true)
    end
  end

  def archived
    @prospect = Prospect.find(params[:prospect][:id])
    new_prospect = @prospect.to_archived(params[:prospect][:agent_id], params[:copy_meta])
    redirect_to( {:controller => 'insight', :action => 'agents', :id => @prospect.prospectable_id}, notice: 'Prospect was successfully archived.')
  end

  def nodup_archived
    @prospect = Prospect.find(params[:id])
    # archived_status = Status.find_or_create_by(:name => "Archived")
    @prospect.update_attribute("archived", true)

    redirect_to( {:controller => 'insight', :action => 'agents', :id => @prospect.prospectable_id}, notice: 'Prospect was successfully archived with no duplication.')
  end

  def process_multiple_pluck
    @prospects = Prospect.find(prospect_params[:prospect_ids])
    @prospects.each do |prospect|
      prospect.to_archived(params[:multiple_prospect][:target_user_id], true)
    end

    redirect_to( {:controller => 'insight', :action => 'agents', :id => params[:multiple_prospect][:agent_id]}, notice: 'Prospect was successfully archived.')
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Insight Engine'
    @page_secondary = 'Let\'s get a view at 10,000 feet.'
    @page_title = 'LeadAccount | Insight Engine'
    @page_icon = 'lightbulb'
  end

  def authorize
    authorize! :manage, current_user.agency
  end

  def gather_agents
    agent = []
    users = current_user.agency.users
    user_ids = users.map{|user| user.id}
    users.each do |user|
      agent << {:id => user.id,
                :first_name => user.first_name,
                :last_name => user.last_name,
                :prospect_count => user.prospects.length}
    end
    return agent
  end

  def prospect_params
    params.require(:multiple_prospect).permit(:target_user_id, :agent_id, :prospect_ids => [])
  end
end
