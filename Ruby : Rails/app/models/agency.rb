class Agency < ActiveRecord::Base
	include RailsSettings::Extend
  has_many :users
  has_many :leads
  has_many :groups
  has_many :pipes
  has_many :prospects, :through => :users
  accepts_nested_attributes_for :users, :allow_destroy => true
  validates_presence_of :name
  has_paper_trail
end
