class Type < ActiveRecord::Base
	scope :of_type, ->(typeable_type) { where('typeable_type = ?', typeable_type) }
end