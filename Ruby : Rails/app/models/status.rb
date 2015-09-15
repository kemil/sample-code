class Status < ActiveRecord::Base
	scope :statusable, ->(statusable) { where(statusable_type: statusable) }
  scope :inactive_deal_statuses, lambda {statusable('Deal').to_a.delete_if{|s| !deal_inactive.include?(s.name)}}
  scope :active_deal_statuses, lambda { statusable('Deal').to_a.delete_if{|s| deal_inactive.include?(s.name)} }

  def self.archived
    return find_or_create_by(name: 'Archived')
  end

  def self.deal_inactive
    return ["Did Not Qualify (financial)", "Did Not Qualify (health)", "Application Rejected", "Sold/Placed", "Not Interested"]
  end
end
