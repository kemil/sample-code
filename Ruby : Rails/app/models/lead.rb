class Lead < ActiveRecord::Base
  has_many :prospects, :dependent => :destroy
  has_many :groups, :through => :prospects, :source => :prospectable, :source_type => 'Group'
  has_many :users, :through => :prospects, :source => :prospectable, :source_type => 'User'
  belongs_to :agency

  scope :orphaned, lambda{where(prospects_count: 0)}
  #scope lead who has all prospect archived
  # scope :archived, lambda{joins(:prospects).where("prospects.status_id = #{Status.archived.id} and prospects.status_id is not NULL").uniq.to_a.delete_if{|x| x.prospects.count >  x.prospects.archived.count}}
  scope :archived, lambda{joins(:prospects).where("prospects.archived = true").uniq.to_a.delete_if{|x| x.prospects.count >  x.prospects.archived.count}}

  has_attached_file :image,
                    :styles => {
                        :original => ["100%", :jpg],
                        :header => ['750x350>',:jpg],
                        :large => ["600x600>",:jpg],
                        :medium => ["300x300>",:jpg],
                        :thumb => ["100x100>",:jpg] },
                    :default_url => ActionController::Base.helpers.asset_path('assets/:attachment/:style/missing-ccff1e07fbebe27d91e81d8bfcb81f86.png')

  has_attached_file :pdf

  geocoded_by :full_street_address
  after_validation :geocode

  def image_from_url(url)
    self.image = URI.parse(url)
    self.save
  end

  def pdf_from_url(url)
    self.pdf = URI.parse(url)
    self.save
  end

  def self.prime_images
    # Create a method to call through the command line to clean up records without images
    Lead.where(image_file_name: nil).find_each do |lead|
      image_url = 'http://3et3jvbtupxhgt.hopto.me:9090/' + lead.order_no + '/' + lead.returned_date.strftime('%Y-%m-%d') + '/tiff/' + lead.order_no + '-' + lead.record_no + '.tif'
      pdf_url = 'http://3et3jvbtupxhgt.hopto.me:9090/' + lead.order_no + '/' + lead.returned_date.strftime('%Y-%m-%d') + '/pdf/' + lead.order_no + '-' + lead.record_no + '.pdf'
      Lead.find(lead.id).delay.image_from_url(image_url)
      Lead.find(lead.id).delay.pdf_from_url(pdf_url)
    end
  end

  def self.filtered(sort_by=nil, sort_in=nil, filter=nil, key=nil)

    unless key.blank? || key == 'blank'
      conditions = "leads.keycode ILIKE '%#{key}%' OR leads.first_name ILIKE '%#{key}%' OR leads.last_name ILIKE '%#{key}%' OR cast(leads.zip_code as text) ILIKE '%#{key}%' OR leads.county ILIKE '%#{key}%' OR cast(leads.returned_date as text) ILIKE '%#{key}%' OR leads.order_no ILIKE '%#{key}%'"
    end

    if filter == 'unassigned'
      leads = key.blank? || key == 'blank' ? archived : where(conditions).archived
    elsif filter == 'fresh'
      leads = key.blank? || key == 'blank' ? orphaned : where(conditions).orphaned
    elsif filter.blank? || (filter == 'unassigned,fresh' || filter == 'fresh,unassigned')
      leads = key.blank? || key == 'blank' ? (archived + orphaned) : (where(conditions).archived + orphaned.where(conditions))
    end

    return order_leads(leads, sort_by, sort_in)
  end

  def zip
    "#{zip_code}-#{zip_ext}"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def ident
    "#{order_no}#{record_no}"
  end

  def full_street_address
    [address_one, city, state].compact.join(', ')
  end

  def self.order_leads(leads, sort_by, sort_in)
    unless sort_by.blank? && sort_in.blank?
      if sort_in == 'asc'
        return leads.sort_by{|x| x[sort_by.to_sym]}
      else
        return leads.sort_by{|x| x[sort_by.to_sym]}.reverse
      end
    else
      return leads
    end
  end

  def self.states
    return self.all.map{|x| x.state}.uniq
  end

  def self.counties
    return self.all.map{|x| x.county}.uniq
  end

  def self.build_report(agency_id, group, sorting, filter, sort_in=nil, sort_by=nil, key=nil)
    all_data = {}
    conditions = []

    sql =  "SELECT leads.*,
            CASE
            WHEN leads.prospects_count = 0
              THEN 'Unassigned'
              ELSE 'Assigned'
            END
            AS prospect_status
            FROM leads
            LEFT JOIN prospects ON prospects.lead_id = leads.id"

    unless key.blank? || key == 'blank'
      conditions << Lead.report_key_condition(group, key)
    end

    conditions = Lead.report_filter_condition(conditions, filter)

    unless sorting.blank?
      sorting_sql = []

      if group[:group] == 'Lead Status'
        sorting_sql << 'prospect_status ASC'
      elsif group[:group] == 'State'
        sorting_sql << "leads.state ASC"
      elsif group[:group] == 'County'
        sorting_sql << "leads.county ASC"
      end

      sorting[:report_sort_by].uniq.each_with_index do |sort, index|
        sorting_sql << "leads.#{sort} #{sorting[:report_sort_in][index]}"
      end
      sorting_sql = sorting_sql.join(", ")
    end

    unless group.blank?

      users_id = User.where(agency_id: agency_id).map { |u| u.id }.uniq
      # conditions << "prospects.prospectable_id IN (#{users_id.join(",")}) AND prospects.prospectable_type = 'User'"
      conditions << "leads.agency_id = #{agency_id}"
      sql << " WHERE " + conditions.join(' AND ') unless conditions.blank?
      sql += " ORDER BY #{sorting_sql}" unless sorting_sql.blank?
      leads = Lead.find_by_sql(sql).uniq

      unless filter[:lead_status].blank?
        if filter[:lead_status] == 'Unassigned'
          leads = leads.delete_if{|x| x.prospect_status == 'Assigned'}
        else
          leads = leads.delete_if{|x| x.prospect_status == 'Unassigned'}
        end
      end

      if group[:group_type] == 'Collate'
        if sort_by == 'lead_status'
          sort_by = 'prospect_status'
        end

        unless sort_in.blank? && sort_by.blank?
          objects = leads.sort_by{|x| x["#{sort_by}"].nil? ? '' : x["#{sort_by}"]}
          objects = leads.reverse if sort_in == 'desc'
        else
          objects = leads
        end
      else
        leads = Lead.generate_count_report(group, leads)
        unless sort_in.blank? && sort_by.blank?
          objects = leads.sort_by{|x| x["#{sort_by}".to_sym].nil? ? '' : x["#{sort_by}".to_sym]}
          objects = leads.reverse if sort_in == 'desc'
        else
          objects = leads
        end
      end

      return objects

    end
  end

private

  def self.report_filter_condition(conditions, filter)
    unless filter[:daterange_from].blank? && filter[:daterange_to].blank?
      conditions << "(DATE(leads.created_at) >= '#{filter[:daterange_from]}' AND DATE(leads.created_at) <= '#{filter[:daterange_to]}')"
    end

    unless filter[:counties].blank?
      conditions << "leads.county IN ('#{filter[:counties].join("', '")}')"
    end

    unless filter[:states].blank?
      conditions << "leads.state IN ('#{filter[:states].join("', '")}')"
    end

    unless filter[:zip_code].blank?
      conditions << "CAST(leads.zip_code AS TEXT) ILIKE '%#{filter[:zip_code]}%'"
    end

    unless filter[:key_code].blank?
      conditions << "leads.keycode ILIKE '%#{filter[:key_code]}%'"
    end

    unless filter[:order_no].blank?
      conditions << "leads.order_no ILIKE '%#{filter[:order_no]}%'"
    end

    return conditions
  end

  def self.report_key_condition(group, key)
    if group[:group_type] == 'Collate'
      conditions = " (leads.keycode ILIKE '%#{key}%' OR leads.first_name ILIKE '%#{key}%' OR
                      leads.last_name ILIKE '%#{key}%' OR
                      to_char(leads.returned_date, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%' OR
                      leads.county ILIKE '%#{key}%' OR leads.order_no ILIKE '%#{key}%') "
    else
      if group[:group] == 'State'
        conditions = " leads.state ILIKE '%#{key}%'"
      elsif group[:group] == 'County'
        conditions = " leads.county ILIKE '%#{key}%'"
      end
    end
    return conditions
  end

  def self.generate_count_report(group, leads)
    if group[:group] == 'Lead Status'
      objs = leads.group_by{|t| t.prospect_status}
      arr = []
      objs.each do |lead, leads|
        obj = {}
        obj[:name] = lead
        obj[:lead_count] = leads.count
        arr << obj
      end
      objects = arr
    elsif group[:group] == 'State'
      objs = leads.group_by{|t| t.state}
      arr = []
      objs.each do |lead, leads|
        obj = {}
        obj[:name] = lead
        obj[:lead_count] = leads.count
        arr << obj
      end
      objects = arr
    elsif group[:group] == 'County'
      objs = leads.group_by{|t| t.county}
      arr = []
      objs.each do |lead, leads|
        obj = {}
        obj[:name] = lead
        obj[:lead_count] = leads.count
        arr << obj
      end
      objects = arr
    end
    return objects

  end
end
