require 'spec_helper'
include ContractHelper
include ApplicationHelper

# Put your acceptance spec helpers inside spec/acceptance/support
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

def build_employment
  address = FactoryGirl.create(:address)
  employee = FactoryGirl.create(:complete_employee, first_name: "Jane", last_name: "Doe", password: "password", gender: "Female", date_of_birth: Date.parse("01/01/1987"), address: address)
  employment = FactoryGirl.create(:employment, employee: employee, employer: Employer.last, salary: 40, start_date: Time.zone.now.to_date, employment_type: "Part-time", position: "Accountant", probation_length: 3, active: true)
  return [employee, employment]
end
