class Tap < ActiveRecord::Base
  belongs_to :tapable, polymorphic: true
  belongs_to :type
  belongs_to :user
  belongs_to :contact
  has_paper_trail

  default_scope {
  	order('taps.created_at DESC')
  }
end
