class Deal < ActiveRecord::Base
	has_many :notes, as: :noteable, :dependent => :destroy
  has_many :taps, as: :tapable, :dependent => :destroy
  belongs_to :prospect
  belongs_to :type
  belongs_to :status
  belongs_to :contact
  belongs_to :carrier
  belongs_to :user
  has_paper_trail

  amoeba do
    enable
  end

  def self.get_briefcase_list(current_user, deal_status=nil, deal_type=nil, tapped=nil, carrier=nil)
    conditions = []
    conditions << "deals.status_id IN (#{deal_status})" unless deal_status.blank?
    conditions << "deals.type_id IN (#{deal_type})" unless deal_type.blank?
    unless carrier.blank?
      unless carrier.split(",").include?("all")
        conditions << "deals.carrier_id IN (#{carrier})"
      end
    end

    unless tapped.blank?
      join = 'LEFT JOIN taps ON "taps"."tapable_id" = "deals"."id"'
      case tapped
      when 'past_week'
        conditions << "taps.tapable_type = 'Deal' AND taps.created_at >= '#{Time.now.beginning_of_week}'"
      when 'past_month'
        conditions << "taps.tapable_type = 'Deal' AND taps.created_at >= '#{Time.now.beginning_of_month}'"
      when 'a_month_from_now'
        conditions << "taps.tapable_type = 'Deal' AND taps.created_at < '#{Time.now.beginning_of_month}'"
      end
    end

    conditions << "prospects.archived = false"
    if conditions.blank? && join.blank?
      deals = current_user.deals
    else
      if join.blank?
        deals = current_user.deals.where(conditions.join(' AND '))
      else
        deals = current_user.deals.joins(join).where(conditions.join(' AND '))
      end
    end

    if tapped == 'never'
      never_deals = []
      deals.each do |d|
        never_deals << d if d.taps.length == 0
      end
      deals = never_deals
    end
    return deals.uniq
  end

  def self.build_report(agency_id, group, sorting, filter, sort_in=nil, sort_by=nil, key=nil)
    all_data = {}
    conditions = []

    if group[:group] == 'Agents'
      sql = "SELECT deals.*, prospects.first_name AS prospect_first_name,
            prospects.last_name AS prospect_last_name, statuses.name as status_name,
            prospects.prospectable_id AS prospectable_id, carriers.name AS carrier_name, types.name AS type_name,
            (SELECT (users.first_name|| ' ' ||users.last_name) FROM users  WHERE users.id = prospects.prospectable_id) AS agent
            FROM deals
            LEFT JOIN prospects ON prospects.id = deals.prospect_id
            LEFT JOIN carriers ON carriers.id = deals.carrier_id
            LEFT JOIN statuses ON statuses.id = deals.status_id
            LEFT JOIN types ON types.id = deals.type_id"
    elsif group[:group] == 'State'
      sql = "SELECT deals.*, prospects.first_name AS prospect_first_name,
            prospects.last_name AS prospect_last_name, statuses.name as status_name,
            carriers.name AS carrier_name, types.name AS type_name,
            (SELECT leads.state FROM leads WHERE leads.id = prospects.lead_id) AS state
            FROM deals
            LEFT JOIN prospects ON prospects.id = deals.prospect_id
            LEFT JOIN carriers ON carriers.id = deals.carrier_id
            LEFT JOIN statuses ON statuses.id = deals.status_id
            LEFT JOIN types ON types.id = deals.type_id"
    elsif group[:group] == 'County'
      sql = "SELECT deals.*, prospects.first_name AS prospect_first_name,
            prospects.last_name AS prospect_last_name, statuses.name as status_name,
            carriers.name AS carrier_name, types.name AS type_name,
            (SELECT leads.county FROM leads WHERE leads.id = prospects.lead_id) AS county
            FROM deals
            LEFT JOIN prospects ON prospects.id = deals.prospect_id
            LEFT JOIN carriers ON carriers.id = deals.carrier_id
            LEFT JOIN statuses ON statuses.id = deals.status_id
            LEFT JOIN types ON types.id = deals.type_id"
    else
      sql = "SELECT deals.*, prospects.first_name AS prospect_first_name,
            prospects.last_name AS prospect_last_name, statuses.name as status_name,
            carriers.name AS carrier_name, types.name AS type_name
            FROM deals
            LEFT JOIN prospects ON prospects.id = deals.prospect_id
            LEFT JOIN carriers ON carriers.id = deals.carrier_id
            LEFT JOIN statuses ON statuses.id = deals.status_id
            LEFT JOIN types ON types.id = deals.type_id"
    end

    unless key.blank? || key == 'blank'
      if group[:group_type] == 'Collate'
        if group[:group] == 'Agents'
          conditions << " ((SELECT COUNT(*) FROM users  WHERE users.id = prospects.prospectable_id AND
                           (users.first_name ILIKE '%#{key}%' OR users.last_name ILIKE '%#{key}%')) > 0 OR
                           prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                           deals.policy_number ILIKE '%#{key}%' OR statuses.name ILIKE '%#{key}%' OR
                           carriers.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR
                           to_char(deals.application_date, 'YYYY-MM-DD') ILIKE '%#{key}%' OR
                           to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
        elsif group[:group] == 'State'
          conditions << " ((SELECT COUNT(*) FROM leads  WHERE leads.id = prospects.lead_id AND
                           leads.state ILIKE '%#{key}%') > 0 OR
                           prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                           deals.policy_number ILIKE '%#{key}%' OR statuses.name ILIKE '%#{key}%' OR
                           carriers.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR
                           to_char(deals.application_date, 'YYYY-MM-DD') ILIKE '%#{key}%' OR
                           to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
        elsif group[:group] == 'County'
          conditions << " ((SELECT COUNT(*) FROM leads  WHERE leads.id = prospects.lead_id AND
                           leads.county ILIKE '%#{key}%') > 0 OR
                           prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                           deals.policy_number ILIKE '%#{key}%' OR statuses.name ILIKE '%#{key}%' OR
                           carriers.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR
                           to_char(deals.application_date, 'YYYY-MM-DD') ILIKE '%#{key}%' OR
                           to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
        else
          conditions << " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                           deals.policy_number ILIKE '%#{key}%' OR statuses.name ILIKE '%#{key}%' OR
                           carriers.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR
                           to_char(deals.application_date, 'YYYY-MM-DD') ILIKE '%#{key}%' OR
                           to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
        end
      else
        if group[:group] == 'Agents'
          conditions << " (SELECT COUNT(*) FROM users  WHERE users.id = prospects.prospectable_id AND
                           (users.first_name ILIKE '%#{key}%' OR users.last_name ILIKE '%#{key}%')) > 0 "
        elsif group[:group] == 'State'
          conditions << " (SELECT COUNT(*) FROM leads  WHERE leads.id = prospects.lead_id AND
                           leads.state ILIKE '%#{key}%') > 0 "
        elsif group[:group] == 'County'
          conditions << " (SELECT COUNT(*) FROM leads  WHERE leads.id = prospects.lead_id AND
                           leads.county ILIKE '%#{key}%') > 0 "
        end
      end
    end

    unless filter[:daterange_from].blank? && filter[:daterange_to].blank?
      conditions << "DATE(prospects.created_at) >= '#{filter[:daterange_from]}' AND DATE(prospects.created_at) <= '#{filter[:daterange_to]}'"
    end

    unless sorting.blank?
      sorting_sql = []
      sorting[:report_sort_by].uniq.each_with_index do |sort, index|
        sorting_sql << "deals.#{sort} #{sorting[:report_sort_in][index]}"
      end
      sorting_sql = sorting_sql.join(", ")
    end

    unless group.blank?

      unless filter[:agents].blank?
        users_id = filter[:agents].map{|x| x.to_i}
      else
        users_id = User.where(agency_id: agency_id).map { |u| u.id }.uniq
      end

      conditions << "prospects.prospectable_id IN (#{users_id.join(",")}) AND prospects.prospectable_type = 'User' AND prospects.archived = false"
      sql << " WHERE " + conditions.join(' AND ') unless conditions.blank?
      sql += " ORDER BY #{sorting_sql}" unless sorting_sql.blank?
      deals = Deal.find_by_sql(sql)

      if group[:group_type] == 'Collate'
        unless sort_in.blank? && sort_by.blank?
          case sort_by
          when 'type'
            sort_by = 'type_name'
          when 'status'
            sort_by = 'status_name'
          when 'name'
            sort_by = 'prospect_first_name'
          when 'carrier'
            sort_by = 'carrier_name'
          end

          if sort_by == 'application_date'
            objects = deals.sort_by{|x| x["#{sort_by}"].blank? ? Time.now : x["#{sort_by}"]}
          else
            objects = deals.sort_by{|x| x["#{sort_by}"].nil? ? '' : x["#{sort_by}"]}
          end
          objects = objects.reverse if sort_in == 'desc'
        else
          objects = deals
        end

      else
        if group[:group] == 'Agents'
          objs = deals.delete_if{|y| y.prospectable_id.nil? }.group_by{|t| t.prospectable_id}
          arr = []
          objs.each do |u, deals|
            unless u.nil?
              obj = {}
              user = User.find(u)
              obj[:first_name] = user.first_name
              obj[:last_name] = user.last_name
              obj[:user_id] = user.id
              obj[:deal_count] = deals.count
              arr << obj
            end
          end
          objects = arr
        elsif group[:group] == 'State'
          objs = deals.delete_if{|y| y.state.nil? }.group_by{|t| t.state}
          arr = []
          objs.each do |lead, deals|
            obj = {}
            obj[:name] = lead
            obj[:deal_count] = deals.count
            arr << obj
          end
          objects = arr
        elsif group[:group] == 'County'
          objs = deals.delete_if{|y| y.county.nil? }.group_by{|t| t.county}
          arr = []
          objs.each do |lead, deals|
            obj = {}
            obj[:name] = lead
            obj[:deal_count] = deals.count
            arr << obj
          end
          objects = arr
        end

        unless sort_in.blank? && sort_by.blank?
          if sort_by == 'state' || sort_by == 'county'
            sort_by = 'name'
          end
          objects = objects.sort_by{|x| x["#{sort_by}".to_sym].nil? ? '' : x["#{sort_by}".to_sym]}
          objects = objects.reverse if sort_in == 'desc'
        else
          objects = objects
        end
      end

      return objects
    end
  end
end
