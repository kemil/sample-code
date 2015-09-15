class Contact < ActiveRecord::Base
  belongs_to :contactable, polymorphic: true
  belongs_to :type
  has_many :taps
  has_many :notes, as: :noteable, :dependent => :destroy
  has_many :locations, as: :locatable, :dependent => :destroy
  has_paper_trail
  accepts_nested_attributes_for :locations, :allow_destroy => true

  validates :first_name, :last_name, presence: true
  validates :ssn, allow_blank: true, format: {
      with:       %r{\b(?!000)(?!666)(?:[0-6]\d{2}|7(?:[0-356]\d|7[012]))(?!00)\d{2}(?!0000)\d{4}\b},
      message:    'this is not a valid social security number'
  }

  scope :primary, -> { where(primary: true) }

  amoeba do
    enable
  end

  def self.latest
    Contact.order(:last_name).last
  end

  def complete_name
    "#{salutation} #{first_name} #{middle_name} #{last_name} #{suffix}"
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
