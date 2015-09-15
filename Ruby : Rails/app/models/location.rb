class Location < ActiveRecord::Base
  belongs_to :locatable, polymorphic: true
  belongs_to :type
  has_paper_trail

  geocoded_by :full_street_address
  after_validation :geocode, if: ->(obj){ obj.longitude.blank? or obj.latitude.blank? }

  scope :primary, -> { where(primary: true) }

  def full_street_address
    [address_one, city, state].compact.join(', ')
  end

  def zip
    "#{zip_code}-#{zip_ext}"
  end

  def name
    "#{address_one}"
  end
end
