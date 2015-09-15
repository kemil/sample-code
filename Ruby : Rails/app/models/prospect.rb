class Prospect < ActiveRecord::Base
  belongs_to :lead
  counter_culture :lead
  belongs_to :prospectable, polymorphic: true
  belongs_to :status
  belongs_to :type
  has_many :deals, :dependent => :destroy
  has_many :notes, as: :noteable, :dependent => :destroy
  has_many :locations, as: :locatable, :dependent => :destroy
  has_many :taps, as: :tapable, :dependent => :destroy
  has_many :abentries, as: :abentryable, :dependent => :destroy

  validates_uniqueness_of :lead_id, scope: [:prospectable_id, :prospectable_type], allow_nil: true

  has_paper_trail
  acts_as_readable :on => :created_at
  before_create :duplication_check
  after_create :generate_location_and_deal
  accepts_nested_attributes_for :locations, :allow_destroy => true

  # scope :archived, lambda{where("status_id = #{Status.archived.id}")}
  scope :archived, lambda{where("archived = true")}

  amoeba do
    enable
  end

  def self.manual_type
    ActiveRecord::Base.connection.execute("select * from types where slug = 'manual_prospect' and typeable_type = 'Prospect'").first["id"]
  end

  def self.pipe_type
    ActiveRecord::Base.connection.execute("select * from types where slug = 'piped_prospect' and typeable_type = 'Prospect'").first["id"]
  end

  def full_name
    "#{salutation} #{first_name} #{middle_name} #{last_name}"
  end

  def to_archived(agent_id, copy_meta)
    # archived_status = Status.find_or_create_by(:name => "Archived")

    self.update_attribute("archived", true)
    if copy_meta == 'on'
      prospect = self.amoeba_dup
      prospect.save
      prospect.update_attributes(:prospectable_id => agent_id, :archived => false)
    else
      prospect = Prospect.new(:lead_id => self.lead_id,
                              :prospectable_id => agent_id,
                              :prospectable_type => 'User',
                              :first_name => self.lead.first_name,
                              :last_name => self.lead.last_name,
                              :middle_name => self.lead.middle_name,
                              :salutation => self.lead.salutation,
                              :type_id => self.type_id)
      prospect.save
    end

    return prospect
  end

  def duplication_check
    unless self.lead_id.nil?
      dup_prospect = Prospect.find_by_prospectable_id_and_prospectable_type_and_lead_id(self.prospectable_id, self.prospectable_type, self.lead_id)
      if dup_prospect.blank?
        return true
      else
        return false
      end
    end
  end

  def generate_location_and_deal
    type = ActiveRecord::Base.connection.execute("select * from types where slug = 'general' and typeable_type = 'Deal'").first
    if self.deals.where({type_id: type["id"], prospect: self, status_id: 21}).blank?
      self.deals.create(type_id: type["id"], prospect: self, status_id: 21)
    end

    unless self.lead.blank?
      self.locations.create(latitude:      self.lead.latitude,
                            longitude:     self.lead.longitude,
                            address_one:   self.lead.address_one,
                            address_two:   self.lead.address_two,
                            city:          self.lead.city,
                            zip_code:      self.lead.zip_code,
                            zip_ext:       self.lead.zip_ext,
                            county:        self.lead.county,
                            state:         self.lead.state,
                            primary:       true,
                            type_id:       35)

      unless self.lead.phone.blank?
        phone_abentry_type = ActiveRecord::Base.connection.execute("select * from types where slug = 'phone' and typeable_type = 'Abentry'").first
        self.abentries.create(abparam: self.lead.phone, type_id:phone_abentry_type["id"])
      end
    end
  end

  def self.build_report(agency_id, group, sorting, filter, sort_in=nil, sort_by=nil, key=nil)
    all_data = {}
    lead_conditions = []
    non_lead_conditions = []
    conditions = []

    lead_sql = "SELECT prospects.*, users.first_name AS first_username,
               users.last_name AS last_username, leads.state AS state,
               users.id AS user_id, leads.county AS county, statuses.name AS status_name,
               types.name AS type_name  FROM prospects
               LEFT JOIN users ON users.id = prospects.prospectable_id
               INNER JOIN leads ON leads.id = prospects.lead_id
               LEFT JOIN statuses ON statuses.id = prospects.status_id
               LEFT JOIN types ON types.id = prospects.type_id"

    non_lead_sql = "SELECT prospects.*, users.first_name AS first_username,
                   users.last_name AS last_username, users.id AS user_id,
                   statuses.name AS status_name, '' AS state, '' AS county,
                   types.name AS type_name  FROM prospects
                   LEFT JOIN users ON users.id = prospects.prospectable_id
                   LEFT JOIN statuses ON statuses.id = prospects.status_id
                   LEFT JOIN types ON types.id = prospects.type_id"

    unless key.blank? || key == 'blank'
      key_conditions = Prospect.report_key_condition(group, key)
      lead_conditions << key_conditions[0]
      non_lead_conditions << key_conditions[1] unless key_conditions[1].blank?
    end

    filter_conditions = Prospect.report_filter_condition(lead_conditions, non_lead_conditions, filter)
    lead_conditions = filter_conditions[0]
    non_lead_conditions = filter_conditions[1]

    unless sorting.blank?
      lead_sorting_sql = []
      non_lead_sorting_sql = []

      if group[:group] == 'Agents'
        lead_sorting_sql << "prospects.prospectable_id ASC"
        non_lead_sorting_sql << "prospects.prospectable_id ASC"
      elsif group[:group] == 'State'
        lead_sorting_sql << "leads.state ASC"
      elsif group[:group] == 'County'
        lead_sorting_sql << "leads.county ASC"
      end

      sorting[:report_sort_by].uniq.each_with_index do |sort, index|
        lead_sorting_sql << "prospects.#{sort} #{sorting[:report_sort_in][index]}"
        non_lead_sorting_sql << "prospects.#{sort} #{sorting[:report_sort_in][index]}"
      end
      lead_sorting_sql = lead_sorting_sql.join(", ")
      non_lead_sorting_sql = non_lead_sorting_sql.join(", ")
    end

    unless filter[:agents].blank?
      users_id = filter[:agents].map{|x| x.to_i}
    else
      users_id = User.where(agency_id: agency_id).map { |u| u.id }.uniq
    end

    conditions << "users.id IN (#{users_id.join(",")}) AND prospects.prospectable_type = 'User'"
    non_lead_conditions << conditions.join(' AND ') + " AND prospects.lead_id IS NULL "
    lead_conditions << conditions.join(' AND ')

    lead_sql << " WHERE " + lead_conditions.join(' AND ') unless lead_conditions.blank?
    lead_sql += " ORDER BY #{lead_sorting_sql}" unless lead_sorting_sql.blank?
    objects = Prospect.find_by_sql(lead_sql)

    non_lead_sql << " WHERE " + non_lead_conditions.join(' AND ') unless non_lead_conditions.blank?
    non_lead_sql += " ORDER BY #{non_lead_sorting_sql}" unless non_lead_sorting_sql.blank?
    objects += Prospect.find_by_sql(non_lead_sql)

    if group[:group_type] == 'Count'
      objects = Prospect.generate_count_report(group, objects)
      unless sort_in.blank? && sort_by.blank?
        objects = objects.sort_by{|x| x["#{sort_by}".to_sym].nil? ? '' : x["#{sort_by}".to_sym]}
        objects = objects.reverse if sort_in == 'desc'
      else
        objects = objects
      end
    else
      unless sort_in.blank? && sort_by.blank?
        if sort_by == 'type'
          sort_by = 'type_name'
        elsif sort_by == 'status'
          sort_by = 'status_name'
        elsif sort_by == 'agent'
          sort_by = 'first_username'
        end

        objects = objects.sort_by{|x| x["#{sort_by}"].nil? ? '' : x["#{sort_by}"]}
        objects = objects.reverse if sort_in == 'desc'
      else
        if group[:group] == 'Agents'
          objects = objects.sort_by{|x| x["first_username"]}
        elsif group[:group] == 'State'
          objects = objects.sort_by{|x| x["state"]}
        elsif group[:group] == 'County'
          objects = objects.sort_by{|x| x["county"]}
        end
      end
    end
    return objects

  end

private

  def self.report_filter_condition(lead_conditions, non_lead_conditions, filter)
    unless filter[:daterange_from].blank? && filter[:daterange_to].blank?
      lead_conditions << "DATE(prospects.created_at) >= '#{filter[:daterange_from]}' AND DATE(prospects.created_at) <= '#{filter[:daterange_to]}'"
      non_lead_conditions << "DATE(prospects.created_at) >= '#{filter[:daterange_from]}' AND DATE(prospects.created_at) <= '#{filter[:daterange_to]}'"
    end

    unless filter[:counties].blank?
      lead_conditions << "leads.county IN ('#{filter[:counties].join("', '")}')"
    end

    unless filter[:states].blank?
      lead_conditions << "leads.state IN ('#{filter[:states].join("', '")}')"
    end

    unless filter[:zip_code].blank?
      lead_conditions << "CAST(leads.zip_code AS TEXT) ILIKE '%#{filter[:zip_code]}%'"
    end

    unless filter[:key_code].blank?
      lead_conditions << "leads.keycode ILIKE '%#{filter[:key_code]}%'"
    end

    unless filter[:order_no].blank?
      lead_conditions << "leads.order_no ILIKE '%#{filter[:order_no]}%'"
    end

    return lead_conditions, non_lead_conditions
  end

  def self.report_key_condition(group, key)
    if group[:group_type] == 'Count'
      if group[:group] == 'Agents'
        cond = " users.first_name ILIKE '%#{key}%' OR users.last_name ILIKE '%#{key}%' "
        lead_conditions = cond
        non_lead_conditions = cond
      elsif group[:group] == 'State'
        lead_conditions = " leads.state ILIKE '%#{key}%'"
      elsif group[:group] == 'County'
        lead_conditions = " leads.county ILIKE '%#{key}%'"
      end
    else
      if group[:group] == 'Agents'
        cond = " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                  users.first_name ILIKE '%#{key}%' OR prospects.salutation ILIKE '%#{key}%' OR
                  statuses.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR
                  to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
        lead_conditions = cond
        non_lead_conditions  = cond
      elsif group[:group] == 'State'
        lead_conditions = " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                            leads.state ILIKE '%#{key}%' OR prospects.salutation ILIKE '%#{key}%' OR
                            statuses.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
      elsif group[:group] == 'County'
        lead_conditions = " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%' OR
                            prospects.salutation ILIKE '%#{key}%' OR leads.county ILIKE '%#{key}%' OR
                            statuses.name ILIKE '%#{key}%' OR types.name ILIKE '%#{key}%' OR to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
      end
    end
    return lead_conditions, non_lead_conditions
  end

  def self.generate_count_report(group, objects)
    if group[:group] == 'Agents'
      objs = objects.group_by{|t| t.prospectable_id}
      arr = []
      objs.each do |user, prospects|
        unless user.nil?
          obj = {}
          u = User.find(user)
          obj[:first_name] = u.first_name
          obj[:last_name] = u.last_name
          obj[:user_id] = user
          obj[:prospect_count] = prospects.count
          arr << obj
        end
      end
      objects = arr
    elsif group[:group] == 'State'
      objs = objects.group_by{|t| t.state}
      arr = []
      objs.each do |lead, prospects|
        obj = {}
        obj[:name] = lead
        obj[:prospect_count] = prospects.count
        arr << obj
      end
      objects = arr
    elsif group[:group] == 'County'
      objs = objects.group_by{|t| t.county}
      arr = []
      objs.each do |lead, prospects|
        obj = {}
        obj[:name] = lead
        obj[:prospect_count] = prospects.count
        arr << obj
      end
      objects = arr
    end
    return objects
  end

end
