class Group < ActiveRecord::Base
  has_many :locations, as: :locatable
  has_many :prospects, as: :prospectable, :dependent => :delete_all
  has_many :memberships, dependent: :destroy
  has_many :users, :through => :memberships
  has_many :pipes

  belongs_to :agency

  has_ancestry :orphan_strategy => :adopt

  resourcify
end
