class Abentry < ActiveRecord::Base
  belongs_to :abentryable, polymorphic: true
  belongs_to :type

  validates_presence_of :abparam
  validates_format_of :abparam, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => 'Email is invalid', :if => Proc.new { |abentry| abentry.type_id == Abentry.abentry_email_type_id }

  private

  def self.abentry_email_type_id
    return ApplicationController.helpers.abentry_types.delete_if { |type| type[0] != 'Email'  }.flatten[1]
  end

  def self.abentry_phone_type_id
    return ApplicationController.helpers.abentry_types.delete_if { |type| type[0] != 'Phone'  }.flatten[1]
  end

  def self.abentry_fax_type_id
    return ApplicationController.helpers.abentry_types.delete_if { |type| type[0] != 'Fax'  }.flatten[1]
  end
end
