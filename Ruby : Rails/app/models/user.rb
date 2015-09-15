class User < ActiveRecord::Base
  include RailsSettings::Extend
  after_create :assign_basic_role
  after_create :set_notification_default

  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :locations, as: :locatable
  has_many :prospects, as: :prospectable, :dependent => :destroy
  has_many :notes, :dependent => :destroy
  has_many :deals, :through => :prospects
  has_many :memberships
  has_many :groups, :through => :memberships
  has_many :pipes, as: :pipeable, :dependent => :destroy
  has_many :taps
  belongs_to :agency
  has_paper_trail
  acts_as_reader

  has_attached_file :avatar,
                    :styles => {:medium => "300x300>", :thumb => "100x100>"},
                    :default_url => 'http://aws.lead.ac/assets/missing.png'
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

  def full_name
    "#{first_name} #{last_name}"
  end

  def name
    "#{first_name} #{last_name}"
  end

  def active_prospects(sort_by, sort_in, tapped=nil, deal_status=nil, deal_type=nil, carrier=nil, received=nil, read=nil, key=nil)

    # archived_status = Status.archived
    sort_active_prospects(sort_by, sort_in, tapped, deal_status, deal_type, carrier, received, read, key).delete_if{|x| x["archived"] == true}
  end

  def tapping_count
    prospects = self.prospects.where("archived = false")
    prospect_ids = prospects.map { |prospect| prospect.id  }
    count = 0

    unless prospects.blank?
      deals = Deal.find_by_sql("SELECT \"deals\".*, (SELECT COUNT(*) FROM taps  WHERE taps.tapable_id = deals.id  AND taps.tapable_type = 'Deal') AS taps_count FROM deals WHERE prospect_id IN (#{prospect_ids.join(',')})")
      deals.each{|deal| count+=deal.taps_count}
    end

    return count
  end

  def sort_active_prospects(sort_by, sort_in, tapped=nil, deal_status=nil, deal_type=nil, carrier=nil, received=nil, read=nil, key=nil)
    lead_conditions = []
    non_lead_conditions = []
    conditions = []
    joins = []

    unless received.blank?
      case received
      when 'today'
        conditions << "DATE(prospects.created_at) = '#{Date.today}'"
      when 'this_week'
        conditions << "prospects.created_at >= '#{Time.now.beginning_of_week}' AND prospects.created_at <= '#{Time.now.end_of_week}'"
      when 'last_week'
        conditions << "prospects.created_at >= '#{1.week.ago.beginning_of_week}' AND prospects.created_at <= '#{1.week.ago.end_of_week}'"
      when 'last_month'
        conditions << "prospects.created_at >= '#{1.month.ago.beginning_of_month}' AND prospects.created_at <= '#{1.month.ago.end_of_month}'"
      end
    end

    unless key.blank?
      lead_conditions << " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%'
                          OR cast(leads.zip_code as text) ILIKE '%#{key}%' OR leads.county ILIKE '%#{key}%'
                          OR to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
      non_lead_conditions << " (prospects.first_name ILIKE '%#{key}%' OR prospects.last_name ILIKE '%#{key}%'
                              OR to_char(prospects.created_at, 'YYYY-MM-DD HH:MIPM') ILIKE '%#{key}%') "
    end

    if !deal_status.blank? || !deal_type.blank? || !carrier.blank? || !tapped.blank?
      if !tapped.blank? && tapped != 'all'
        joins << 'LEFT JOIN deals ON "prospects"."id" = "deals"."prospect_id" LEFT JOIN taps ON "taps"."tapable_id" = "deals"."id"'
      else
        joins << 'LEFT JOIN deals ON "prospects"."id" = "deals"."prospect_id"'
      end

      conditions << "deals.status_id IN (#{deal_status})" unless deal_status.blank?
      conditions << "deals.type_id IN (#{deal_type})" unless deal_type.blank?
      unless carrier.blank?
        unless carrier.split(",").include?("all")
          conditions << "deals.carrier_id IN (#{carrier})"
        end
      end

      unless tapped.blank?
        case tapped
        when 'past_week'
          conditions << "taps.tapable_type = 'Deal' AND taps.created_at >= '#{Time.now.beginning_of_week}'"
        when 'past_month'
          conditions << "taps.tapable_type = 'Deal' AND taps.created_at >= '#{Time.now.beginning_of_month}'"
        when 'a_month_from_now'
          conditions << "taps.tapable_type = 'Deal' AND taps.created_at < '#{Time.now.beginning_of_month}'"
        end
      end
    end

    lead_conditions = conditions + lead_conditions
    #To make the query more efficient
    if lead_conditions.blank? && joins.blank?
      sql =  "SELECT prospects.*, leads.zip_code AS zip, leads.county as county,

              (SELECT  COUNT(*) FROM read_marks WHERE read_marks.readable_type = 'Prospect'
              AND read_marks.readable_id = prospects.id AND read_marks.user_id = #{self.id}
              AND read_marks.timestamp >= prospects.created_at) AS read,

              (SELECT COUNT(*) FROM deals  WHERE deals.prospect_id = prospects.id) AS deal_count
              FROM prospects
              INNER JOIN leads ON leads.id = prospects.lead_id
              INNER JOIN users ON users.id = prospects.prospectable_id
              WHERE prospects.prospectable_id = #{self.id} AND prospectable_type = 'User' "
    else

      sql =  "SELECT prospects.*, leads.zip_code AS zip, leads.county as county,

              (SELECT  COUNT(*) FROM read_marks WHERE read_marks.readable_type = 'Prospect'
              AND read_marks.readable_id = prospects.id AND read_marks.user_id = #{self.id}
              AND read_marks.timestamp >= prospects.created_at) AS read,

              (SELECT COUNT(*) FROM deals  WHERE deals.prospect_id = prospects.id) AS deal_count
              FROM prospects
              INNER JOIN leads ON leads.id = prospects.lead_id
              INNER JOIN users ON users.id = prospects.prospectable_id "
      sql << joins.join(' ')
      sql += " WHERE prospects.prospectable_id = #{self.id} AND prospectable_type = 'User'"
      sql << " AND " + lead_conditions.join(' AND ')

    end

    object = self.prospects.find_by_sql(sql)

    #collect non-lead prospect
    non_lead_conditions = conditions + non_lead_conditions
    non_lead_sql = "SELECT prospects.*, (SELECT  COUNT(*) FROM read_marks WHERE read_marks.readable_type = 'Prospect'
                    AND read_marks.readable_id = prospects.id AND read_marks.user_id = #{self.id}
                    AND read_marks.timestamp >= prospects.created_at) AS read,

                    (SELECT COUNT(*) FROM deals  WHERE deals.prospect_id = prospects.id) AS deal_count
                    FROM prospects
                    INNER JOIN users ON users.id = prospects.prospectable_id "
    if non_lead_conditions.blank? && joins.blank?
      non_lead_sql += " WHERE prospects.prospectable_id = #{self.id} AND prospectable_type = 'User' AND prospects.lead_id IS NULL"
      object += self.prospects.find_by_sql(non_lead_sql)
    else
      non_lead_sql << joins.join(' ')
      non_lead_sql += " WHERE prospects.prospectable_id = #{self.id} AND prospectable_type = 'User' AND prospects.lead_id IS NULL"
      non_lead_sql << " AND " + non_lead_conditions.join(' AND ')
      object += self.prospects.find_by_sql(non_lead_sql)
    end

    #generate prospects in array that ready for table view
    prospects = generate_prospects(tapped, object)

    unless read.blank?
      if read == 'yes'
        prospects = prospects.delete_if{| prospect | prospect["unread"] == 0 }
      elsif read == 'no'
        prospects = prospects.delete_if{| prospect | prospect["unread"] == 1 }
      else
        prospects = prospects
      end
    end

    if sort_in == 'asc'
      return prospects.uniq.sort_by{|x| x["#{sort_by}"]}
    else
      return prospects.uniq.sort_by{|x| x["#{sort_by}"]}.reverse
    end
  end

  def chart_hash
    chart_hash = []
    prospects = self.prospects.where("prospects.created_at >= '#{3.month.ago.beginning_of_month}'")
    three_count = 0
    two_count = 0
    one_count = 0
    count = 0

    prospects.each do |p|
      if p.created_at.month == 3.month.ago.month
        three_count += 1
      elsif p.created_at.month == 2.month.ago.month
        two_count += 1
      elsif p.created_at.month == 1.month.ago.month
        one_count += 1
      elsif p.created_at.month == 0.month.ago.month
        count += 1
      end
    end

    chart_hash << {"x" => three_count, "y" => 3.month.ago.to_i*1000}
    chart_hash << {"x" => two_count, "y" => 2.month.ago.to_i*1000}
    chart_hash << {"x" => one_count, "y" => 1.month.ago.to_i*1000}
    chart_hash << {"x" => count, "y" => 0.month.ago.to_i*1000}

    return chart_hash

  end

private
  def assign_basic_role
    self.add_role :basic, self.agency
  end

  def set_notification_default
    self.settings["notifications.new_prospect"] = "1"
  end

  def generate_prospects(tapped, object)
    prospects = []
    if tapped == 'never'
      object.map do |p|
        taps = 0
        p.deals.each do |d|
          taps += d.taps.length
        end

        if taps == 0
          prospects << {"first_name" => p.first_name,
                        "last_name" => p.last_name,
                        "created_at" => p.created_at,
                        "working_deals" => p.deal_count,
                        "zip_code" => p.zip,
                        "county" => p.county,
                        "status_id" => p.status_id,
                        "prospect" => p,
                        "unread" => p.read,
                        "archived" => p.archived }
        end
      end
    else
      object.map do |p|
        unless p.lead_id.nil?
          prospects << { "first_name" => p.first_name,
                         "last_name" => p.last_name,
                         "created_at" => p.created_at,
                         "working_deals" => p.deal_count,
                         "zip_code" => p.zip,
                         "county" => p.county,
                         "status_id" => p.status_id,
                         "prospect" => p,
                         "unread" => p.read,
                         "archived" => p.archived }
        else
          prospects << { "first_name" => p.first_name,
                         "last_name" => p.last_name,
                         "created_at" => p.created_at,
                         "working_deals" => p.deal_count,
                         "zip_code" => '',
                         "county" => '',
                         "status_id" => p.status_id,
                         "prospect" => p,
                         "unread" => p.read,
                         "archived" => p.archived }
        end
      end
    end

    return prospects
  end

end
