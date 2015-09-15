class ApplicationController < ActionController::Base
  check_authorization :unless => :do_not_check_authorization?

  before_filter do
    resource = controller_name.singularize.to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  # check_authorization <-- add this later
  before_filter :authenticate_user!
  before_filter :load_globals

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
    ## to avoid deprecation warnings with Rails 3.2.x (and incidentally using Ruby 1.9.3 hash syntax)
    ## this render call should be:
    # render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: false
  end

  protected
  def load_globals
    @current_time = Date.current.to_formatted_s(:long_ordinal)
    if user_signed_in?
      @triage_count = current_user.agency.leads.orphaned.count
      @tapping_count = current_user.tapping_count
    end
  end

  private
  def do_not_check_authorization?
    respond_to?(:devise_controller?) or
    active_admin_controller?
  end

  def active_admin_controller?
    self.kind_of?(ActiveAdmin::BaseController)
  end

  def make_persistent_option
    determine_per_page
    determine_page
    determine_sort
  end

  def session_name_template
    return "#{params[:controller]}_#{params[:action]}#{params[:repository_id]}#{params[:id]}_#{current_user.id}"
  end

  def determine_per_page
    unless params[:per_page].blank?
      session["length_select_#{session_name_template}"] = nil
      session["curr_page#{session_name_template}"] = nil
    end

    if session["length_select_#{session_name_template}"].blank?
      @per_page = params[:per_page].blank? ? 10 : params[:per_page]
      session["length_select_#{session_name_template}"] = @per_page
    else
      @per_page = session["length_select_#{session_name_template}"]
    end
  end

  def determine_page
    unless params[:page].blank?
      session["curr_page#{session_name_template}"] = nil
    end

    if session["curr_page#{session_name_template}"].blank?
      @page = params[:page].blank? ? 1 : params[:page]
      session["curr_page#{session_name_template}"] = @page
    else
      @page = session["curr_page#{session_name_template}"]
    end
  end

  def determine_sort
    unless params[:sort_in].blank?
      session["sort_in#{session_name_template}"] = nil
    end

    unless params[:sort_by].blank?
      session["sort_by#{session_name_template}"] = nil
    end

    if session["sort_in#{session_name_template}"].blank?
      @sort_in = params[:sort_in].blank? ? 'asc' : params[:sort_in]
      session["sort_in#{session_name_template}"] = @sort_in
    else
      @sort_in = session["sort_in#{session_name_template}"]
    end

    if session["sort_by#{session_name_template}"].blank?
      @sort_by = params[:sort_by].blank? ? 'id' : params[:sort_by]
      session["sort_by#{session_name_template}"] = @sort_by
    else
      @sort_by = session["sort_by#{session_name_template}"]
    end
  end

  def prepare_deal_filters
    @deal_statuses = Status.statusable('Deal')
  end
end
