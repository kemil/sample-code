class DashController < ApplicationController
  before_action :authorize
  before_action :set_info

  def index
    @chart_hash = current_user.chart_hash
    @pros_this_week = objs = current_user.active_prospects('id', @sort_in, nil, nil, nil, nil, 'this_week')
    @fresh_count = current_user.agency.leads.orphaned.length
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_info
    @page_header = 'Dashboard'
    @page_title = 'LeadAccount | Dashboard'
    @page_icon = 'dashboard'
  end

  def authorize
    authorize! :read, current_user.agency
  end
end
