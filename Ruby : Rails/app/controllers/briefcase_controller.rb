class BriefcaseController < ApplicationController
  before_action :authorize
  before_action :set_info
  before_filter :prepare_deal_filters

  def index
    persistent_options
    @deals = Deal.get_briefcase_list(current_user, @deal_status, @deal_type, @tapped, @carrier)
  end

  def get_briefcase
    persistent_options
    @deals = Deal.get_briefcase_list(current_user, @deal_status, @deal_type, @tapped, @carrier)
  end

  private
  def set_info
    @page_header = 'Briefcase'
    @page_title = 'LeadAccount | Briefcase'
    @page_class = 'Briefcase'
    @page_icon = 'briefcase'
  end

  def authorize
    authorize! :read, current_user.agency
  end

  def session_briefcase_template
    return "filter_briefcase_#{current_user.id}"
  end

  def persistent_options
    unless params[:deal_status].nil?
      session["deal_status_#{session_briefcase_template}"] = nil
    end

    if session["deal_status_#{session_briefcase_template}"].nil?
      @deal_status = params[:deal_status]
      session["deal_status_#{session_briefcase_template}"] = @deal_status
    else
      @deal_status = session["deal_status_#{session_briefcase_template}"]
    end

    unless params[:deal_type].nil?
      session["deal_type_#{session_briefcase_template}"] = nil
    end

    if session["deal_type_#{session_briefcase_template}"].nil?
      @deal_type = params[:deal_type]
      session["deal_type_#{session_briefcase_template}"] = @deal_type
    else
      @deal_type = session["deal_type_#{session_briefcase_template}"]
    end


    unless params[:tapped].nil?
      session["tapped_#{session_briefcase_template}"] = nil
    end

    if session["tapped_#{session_briefcase_template}"].nil?
      @tapped = params[:tapped]
      session["tapped_#{session_briefcase_template}"] = @tapped
    else
      @tapped = session["tapped_#{session_briefcase_template}"]
    end


    unless params[:carrier].nil?
      session["carrier_#{session_briefcase_template}"] = nil
    end

    if session["carrier_#{session_briefcase_template}"].nil?
      @carrier = params[:carrier]
      session["carrier_#{session_briefcase_template}"] = @carrier
    else
      @carrier = session["carrier_#{session_briefcase_template}"]
    end
  end
end
