class Pipe < ActiveRecord::Base
  belongs_to :pipeable, polymorphic: true
  belongs_to :group
  belongs_to :type
  belongs_to :agency

  def name
    "#{filter_param}"
  end
end
