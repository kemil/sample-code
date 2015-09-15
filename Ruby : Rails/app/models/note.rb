class Note < ActiveRecord::Base
  belongs_to :noteable, polymorphic: true
  belongs_to :user
  has_paper_trail

  has_attached_file :attachment
end
