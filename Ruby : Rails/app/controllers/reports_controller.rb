class ReportsController < ApplicationController
  before_action :set_info

  def index
    @users = User.where(agency_id: current_user.agency_id).order(:first_name)
    @counties = Lead.counties
    @states = Lead.states
    @deal_statuses = Status.statusable('Deal')
    @prospect_columns = prospect_columns
    @deal_columns = deal_columns
    @lead_columns = lead_columns
  end

  def result
    @objects = 'first_load'
  end

  def get_report_results
    make_persistent_option

    @parameters = params.delete_if{|x,y| x == 'utf8'}.to_query

    if !params[:prospect_agent_group].blank?
      @objects = Kaminari.paginate_array(Prospect.build_report(current_user.agency_id, params[:prospect_agent_group], params[:prospect_agent_sorting], params[:prospect_agent_filter], params[:sort_in], params[:sort_by], params[:key])).page(@page).per(@per_page)
    elsif !params[:agents_summary_group].blank?
      @objects = Kaminari.paginate_array(Deal.build_report(current_user.agency_id, params[:agents_summary_group], params[:agents_summary_sorting], params[:agents_summary_filter], params[:sort_in], params[:sort_by], params[:key])).page(@page).per(@per_page)
    else
      @objects = Kaminari.paginate_array(Lead.build_report(current_user.agency_id, params[:lead_group], params[:lead_sorting], params[:lead_filter], params[:sort_in], params[:sort_by], params[:key])).page(@page).per(@per_page)
    end

    if params[:page].nil? && params[:per_page].nil? && params[:key].nil? && params[:sort_in].nil? && params[:sort_by].nil?
      render :partial => 'widgets/modules/reports/result', content_type: 'text/html'
    end
  end

  def generate_csv
    @parameters = params.delete_if{|x,y| x == 'utf8'}.to_query
    if !params[:prospect_agent_group].blank?
      @objects = Prospect.build_report(current_user.agency_id, params[:prospect_agent_group], params[:prospect_agent_sorting], params[:prospect_agent_filter], params[:sort_in], params[:sort_by], params[:key])
    elsif !params[:agents_summary_group].blank?
      @objects = Deal.build_report(current_user.agency_id, params[:agents_summary_group], params[:agents_summary_sorting], params[:agents_summary_filter], params[:sort_in], params[:sort_by], params[:key])
    else
      @objects = Lead.build_report(current_user.agency_id, params[:lead_group], params[:lead_sorting], params[:lead_filter], params[:sort_in], params[:sort_by], params[:key])
    end
    destination = determine_csv_destination
    CSV.open(destination, "w") do |csv|
      csv << report_csv_headers
      if !params[:prospect_agent_group].blank?
        csv_prospect_report_content(csv)
      elsif !params[:agents_summary_group].blank?
        csv_deal_report_content(csv)
      elsif !params[:lead_group].blank?
        csv_lead_report_content(csv)
      end
    end
    send_file destination
  end

  private

    def set_info
      @page_header = 'Reports'
      @page_secondary = ''
      @page_title = 'LeadAccount | Reports'
      @page_icon = 'bar-chart'
    end

    def prospect_columns
      cols = Prospect.column_names
      screen_cols = []
      cols.delete_if{|x| x == 'prospectable_type'}.each do |col|
        if col.include?('_id')
          screen_cols << [col.gsub('_id', '').titleize, col]
        else
          screen_cols << [col.titleize, col]
        end
      end
      return screen_cols
    end

    def deal_columns
      cols = Deal.column_names
      screen_cols = []
      cols.each do |col|
        if col.include?('_id')
          screen_cols << [col.gsub('_id', '').titleize, col]
        else
          screen_cols << [col.titleize, col]
        end
      end
      return screen_cols
    end

    def lead_columns
      cols = Lead.column_names
      screen_cols = []
      cols.each do |col|
        if col.include?('_id')
          screen_cols << [col.gsub('_id', '').titleize, col]
        else
          screen_cols << [col.titleize, col]
        end
      end
      return screen_cols
    end

    def determine_csv_destination
      if !params[:prospect_agent_group].blank?
        report_module = 'Prospect'
        group = params[:prospect_agent_group][:group]
        group_type = params[:prospect_agent_group][:group_type]
      elsif !params[:agents_summary_group].blank?
        report_module =  'Deal'
        group = params[:agents_summary_group][:group]
        group_type = params[:agents_summary_group][:group_type]
      elsif !params[:lead_group].blank?
        report_module = 'Lead'
        group = params[:lead_group][:group]
        group_type = params[:lead_group][:group_type]
      end

      dir = "#{Rails.root}/csvs/#{report_module}/#{group}/#{group_type}"
      FileUtils.mkdir_p(dir) unless File.exist?(dir)

      return "#{dir}/Reports_#{report_module}_#{group}_#{group_type}_#{Time.now.strftime('%m%d%Y')}.csv"
    end

    def report_csv_headers
      if !params[:prospect_agent_group].blank?
        if params[:prospect_agent_group][:group_type] == 'Collate'
          if params[:prospect_agent_group][:group].blank?
            return ["First Name", "Last Name", "Salutation", "Created At", "Status", "Type"]
          else
            return ["#{params[:prospect_agent_group][:group]}", "First Name", "Last Name", "Salutation", "Created At", "Status", "Type"]
          end
        elsif params[:prospect_agent_group][:group_type] == 'Count'
          if params[:prospect_agent_group][:group] == 'Agents'
            return ["First Name", "Last Name", "Prospect Count"]
          else
            return [params[:prospect_agent_group][:group], "Prospect Count"]
          end
        end
      elsif !params[:agents_summary_group].blank?
        if params[:agents_summary_group][:group_type] == 'Collate'
          if params[:agents_summary_group][:group].blank?
            return ["Name", "Policy Number", "Carrier", "Application Date", "Status", "Type", "Created At"]
          else
            return ["#{params[:agents_summary_group][:group]}", "Name", "Policy Number", "Carrier", "Application Date", "Status", "Type", "Created At"]
          end
        elsif params[:agents_summary_group][:group_type] == 'Count'
          if params[:agents_summary_group][:group] == 'Agents'
            return ["First Name", "Last Name", "Deal Count"]
          else
            return ["#{params[:agents_summary_group][:group]}", "Deal Count"]
          end
        end
      elsif !params[:lead_group].blank?
        group = params[:lead_group][:group]
        if params[:lead_group][:group_type] == 'Collate'
          if group == 'Lead Status'
            return ["#{group}",  "Keycode", "First Name", "Last Name", "Zip Code", "State", "County", "Returned Date", "Order No"]
          elsif group == 'State'
            return ["#{group}",  "Keycode", "First Name", "Last Name", "Zip Code", "County", "Returned Date", "Order No"]
          elsif group == 'County'
            return ["#{group}",  "Keycode", "First Name", "Last Name", "Zip Code", "State", "Returned Date", "Order No"]
          else
            return ["Keycode", "First Name", "Last Name", "Zip Code", "State", "County", "Returned Date", "Order No"]
          end
        elsif params[:lead_group][:group_type] == 'Count'
          return ["#{params[:lead_group][:group]}", 'Lead Count']
        end
      end
    end


    def csv_prospect_report_content(csv)
      if params[:prospect_agent_group][:group_type] == 'Collate'
        @objects.each do |prospect|
          prospect_rows = [prospect.first_name , prospect.last_name , prospect.salutation , prospect.created_at.strftime('%Y-%m-%d') , prospect.status_name.blank? ? '' : prospect.status_name.titleize , prospect.type_name.blank? ? '' : prospect.type_name.titleize]
          if params[:prospect_agent_group][:group] == 'Agents'
            csv << ["#{prospect.first_username} #{prospect.last_username}"] + prospect_rows
          elsif params[:prospect_agent_group][:group] == 'State'
            csv << [prospect.state] + prospect_rows
          elsif params[:prospect_agent_group][:group] == 'County'
            csv << [prospect.county] + prospect_rows
          else
            csv << prospect_rows
          end
        end
      elsif params[:prospect_agent_group][:group_type] == 'Count'
        @objects.each do |prospect|
          if params[:prospect_agent_group][:group] == 'Agents'
            csv << [prospect[:first_name], prospect[:last_name], prospect[:prospect_count]]
          else
            csv << [prospect[:name], prospect[:prospect_count]]
          end
        end
      end
    end

    def csv_deal_report_content(csv)
      if params[:agents_summary_group][:group_type] == 'Collate'
        @objects.each do |deal|
          deal_rows = ["#{deal.prospect_first_name} #{deal.prospect_last_name}", deal.policy_number, deal.carrier_name, deal.application_date.blank? ? '' : deal.application_date.strftime('%Y-%m-%d'), deal.status_name.blank? ? '' : deal.status_name.titleize, deal.type_name.blank? ? '' : deal.type_name.titleize, deal.created_at.strftime('%Y-%m-%d')]
          if params[:agents_summary_group][:group] == 'Agents'
            csv << [deal.agent] + deal_rows
          elsif params[:agents_summary_group][:group] == 'State'
            csv << [deal.state] + deal_rows
          elsif params[:agents_summary_group][:group] == 'County'
            csv << [deal.county] + deal_rows
          else
            csv << deal_rows
          end
        end
      elsif params[:agents_summary_group][:group_type] == 'Count'
        @objects.each do |agent|
          if params[:agents_summary_group][:group] == 'Agents'
            csv << [agent[:first_name], agent[:last_name], agent[:deal_count]]
          else
            csv << [agent[:name], agent[:deal_count]]
          end
        end
      end
    end

    def csv_lead_report_content(csv)
      group = params[:lead_group][:group]
      if params[:lead_group][:group_type] == 'Collate'
        @objects.each do |lead|
          if group == 'Lead Status'
            csv << [lead.prospect_status, lead.keycode, lead.first_name, lead.last_name, lead.zip_code, lead.state, lead.county.blank? ? '' : lead.county.titleize, lead.returned_date.strftime('%Y-%m-%d %I:%M%p'), lead.order_no]
          elsif group == 'State'
            csv << [lead.state, lead.keycode, lead.first_name, lead.last_name, lead.zip_code, lead.county.blank? ? '' : lead.county.titleize, lead.returned_date.strftime('%Y-%m-%d %I:%M%p'), lead.order_no]
          elsif group == 'County'
            csv << [lead.county, lead.keycode, lead.first_name, lead.last_name, lead.zip_code, lead.state, lead.returned_date.strftime('%Y-%m-%d %I:%M%p'), lead.order_no]
          else
            csv << [lead.keycode, lead.first_name, lead.last_name, lead.zip_code, lead.state, lead.county, lead.returned_date.strftime('%Y-%m-%d %I:%M%p'), lead.order_no]
          end
        end
      elsif params[:lead_group][:group_type] == 'Count'
        @objects.each do |lead|
          csv << [lead[:name], lead[:lead_count]]
        end
      end
    end
end
