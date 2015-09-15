class BlackbookController < ApplicationController
  before_action :authorize
  before_action :set_info
  before_filter :prepare_deal_filters

  def index
    flash.clear
    @prospects = 'first_load'
  end

  def get_blackbook_prospect
    make_persistent_option

    @key = (params[:key].blank? || params[:key] == 'blank') ? nil : params[:key]
    objs = current_user.active_prospects(@sort_by, @sort_in, params[:tapped], params[:deal_status], params[:deal_type], params[:carrier], params[:received], params[:read], @key)

    per_page = @per_page == '-1' ? objs.length : @per_page
    @prospects = Kaminari.paginate_array(objs).page(@page).per(per_page)

    if params[:page].nil? && params[:per_page].nil? && params[:key].nil? && params[:sort_in].nil? && params[:sort_by].nil? && params[:deal_status].nil? && params[:deal_type].nil? && params[:carrier].nil? && params[:tapped].nil? && params[:received].nil? && params[:read].nil?
      render :partial => 'widgets/modules/prospects/table_static', content_type: 'text/html'
    end
  end

  def process_multiple_pluck
    if can? :manage, current_user.agency
      @prospects = Prospect.find(prospect_params[:prospect_ids])
      @prospects.each do |prospect|
        prospect.to_archived(params[:multiple_prospect][:target_user_id], true)
      end
    else
      raise "Not allowed"
    end

    redirect_to(blackbook_path, notice: 'Prospect was successfully archived.')
  end

  def unread_prospect
    @prospect = Prospect.find(params[:id])
    if @prospect.prospectable == current_user
      if params[:mark] == 'read'
        @prospect.mark_as_read! :for => current_user
      else
        @prospect.read_marks.where(:user_id => current_user.id).delete_all
      end
    end
  end

  def multiple_print
    @prospects = Prospect.find(prospect_params[:prospect_ids])
    render :layout => false
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Blackbook'
    @page_secondary = 'Your books of prospects. Let\'s do some closing.'
    @page_title = 'LeadAccount | Blackbook'
    @page_icon = 'money'
  end

  def authorize
    authorize! :read, current_user.agency
  end

  def prospect_params
    params.require(:multiple_prospect).permit(:target_user_id, :agent_id, :prospect_ids => [])
  end
end
