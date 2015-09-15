require 'acceptance/acceptance_helper'

feature 'Employee file details', %q{
  In order to view all the information related to an Employee
  As an Employer
  I want see the employee file when I click an employees name
}, acceptance: true do

  background do
    @employer = create(:user_with_organisation)
    @employee = create(:user)

    organisation              = @employer.organisations.first
    organisation.phone        = '1234567890'
    organisation.employees    = @employee
    organisation.save

    @contract_type  = create(:contract_type)
    sample_contract = create(:complete_contract)

    build_contract_details(sample_contract)

    @contract              = Contract.create_from_contract(@employer.active_ownership(organisation), sample_contract)
    generator              = EmploymentGenerator.new(@contract)
    @employment, @employee = generator.generate_employment_objects
    @employment.activate
    @employment.update_attribute(:accepted, true)
  end

  scenario 'Employee file page', js: true do
    # Given I am an employer
    sign_in @employer
    # And I visit 'Employee Files'
    visit employee_files_path
    click_link @employee.memberships.last.name
    # Then I should see the Employee File
    page.should have_xpath "//img[contains(@src, \"avatar.png\")]"
    page.should have_xpath "//select[@id = 'membership_management_option']/option[text() = 'Archive file']"
    page.should have_xpath "//select[@id = 'membership_management_option']/option[text() = 'Make admin']"
    # And I should see a personal details section (Title, First name, Last Name, Middle Name, Know as, Gender, Address, Nationality, Date of Birth, Marital Status, Tax File Number, Personal email, Personal mobile number, Home phone number)
    page.should have_content "Title"
    page.should have_content "First name"
    page.should have_content "Last name"
    page.should have_content "Middle name"
    page.should have_content "Known as"
    page.should have_content "Gender"
    page.should have_content "Address"
    page.should have_content "Nationality"
    page.should have_content "Date of birth"
    page.should have_content "Marital status"
    page.should have_content "Personal email"
    page.should have_content "Personal mobile number"
    page.should have_content "Home phone number"

    # And I should see an Employment details section (Employee code, Location, Employment Type, Position, Salary, Manager, Start date, Length of Probation, Company email, Company mobile, Company landline)
    page.should have_content "Employee code"
    page.should have_content "Location"
    page.should have_content "Employment Type"
    page.should have_content "Position"
    page.should have_content "Salary"
    page.should have_content "Primary manager"
    page.should have_content "Secondary manager"
    page.should have_content "Start date"
    page.should have_content "Length of Probation"
    page.should have_content "Company email"
    page.should have_content "Company mobile"
    page.should have_content "Company landline"
    page.should have_content "Synchronise with Xero payroll?"
    # And I should see Edit links for Personal details and Employment details
    page.should have_xpath('//a', :text => "Edit", :count => 6)
    # And I should see a Documents section with a Create new link
    page.should have_content "Add New"
    # And I should see all documents related to the employee listed in the documents section
    page.should have_content "#{@contract.name} - #{@contract.contract_type.title}"
  end

  scenario 'View tax declaration' do
    sign_in @employer
    @employee.active_membership.tax_declaration.update_attributes tax_resident: true
    visit membership_path(@employee.active_membership)

    expect(page).to have_content 'Tax declaration'
    expect(page).to have_content I18n.t('tax_declaration.tax_resident')
    expect(page).to have_content I18n.t('tax_declaration.tax_free')
    expect(page).to have_no_content I18n.t('tax_declaration.senior_tax_offset')
    expect(page).to have_no_content I18n.t('tax_declaration.dependent_tax_offset')
    expect(page).to have_content I18n.t('tax_declaration.tax_financial_supplement_debt')
  end

  # TODO: this test should not be here as it is out of context for this feature
  scenario "Employee viewing membership page" do
    @employer.organisations.first.employees = @employee
    sign_in @employee
    visit membership_path(@employee.active_membership.id)
    page.should_not have_content "Make admin"
  end
end
