require 'acceptance/acceptance_helper'

feature 'Employee dashboard', %q{
  In order to access my employment details.
  As an Employee
  I want a employee dashboard
}, acceptance: true do
  include ContractHelper

  let(:superannuation_fund) { create(:superannuation_fund) }
  let(:signature_string) { 'data:image/png;base64,' + Base64.encode64(File.read(Rails.root.join('spec/fixtures/signature.png'))).gsub!("\n", '') }

  background do
    @employer = FactoryGirl.create(:user_with_organisation)
    sample_contract = FactoryGirl.create(:complete_contract, type: 'Document')
    build_contract_details(sample_contract)
    @contract = Contract.create_from_contract(@employer.active_ownership(@employer.organisations.first), sample_contract)
    @contract.set_value_for("position", "Accountant")
    generator = EmploymentGenerator.new(@contract)
    @employment, @employee = generator.generate_employment_objects
    @employment.activate
    @employment.tax_declaration.update_attributes(tax_file_number: "123456782", tax_signature: signature_string)
    @employee.update_attributes(password: "password")
    @employer.first_organisation.employing_entities << EmployingEntity.new(name: "My Random Employing Entity")
    @manager = FactoryGirl.create(:user, first_name: "Mr", last_name: "Manager")
    @employer.first_organisation.employees = @manager
    @employee.memberships.first.update_attributes(managers_list: @manager.memberships.first.id)
  end

  scenario 'Employee sign-in', js: true do
    @employee.active_employee_membership.update_column(:superannuation_fund_id, superannuation_fund)
    @employee.active_employee_membership.update_attributes(roster: "Annum", salary: 45)
    @employee.active_employee_membership.update_attributes(employing_entity_id: @employer.first_organisation.employing_entities.first.id)

    # Given I am an employee
    @employee.should_not be_nil
    # And I log into Employment Hero Then I should see my Dashboard
    sign_in @employee
    page.should have_content "Employee Dashboard"

    visit profile_employee_dashboard_index_path
    page.should have_content "Details"
    page.should have_content "Banking"
    page.should have_content "Superannuation"
    # And I should see a progress bar indicating my profile completeness
    page.should have_content "Your profile is 29% complete."
    # And I should see my Employment details
    page.should have_content "Accountant"
    page.should have_content "123456782"
    page.should have_content superannuation_fund.fund_name
    page.should have_content superannuation_fund.fund_abn
    page.should have_content superannuation_fund.product_id_number
    page.should have_content superannuation_fund.member_number
    page.should have_content superannuation_fund.account_name
    page.should have_content "$45.00/Annum"
    page.should have_content "My Random Employing Entity"
    # And it shows my managers name
    page.should have_content "Mr Manager"

    within ".superannuation-fund" do
      click_link 'Edit'
    end

    fill_in "Fund name", with: "SweetSuperFundName"
    sign_signature "#signature-pad-wrapper"
    click_button "Save"
    page.should have_content "SweetSuperFundName"
    # And I should see a list of all my Employment documents
    click_link 'Dashboard'
    visit employee_documents_path
    page.should have_content "Sample Contract"
  end

  scenario 'Employee viewing signed document' do
    @contract.update_attribute(:recipient_email, "employee@example.com")
    @contract.update_attribute(:sender, @employer.active_ownership(@employer.organisations.first))
    @contract.update_attribute(:organisation, @employer.organisations.first)
    @contract.update_attribute(:is_signed, true)
    sign_in @employee
    visit employee_documents_path
    click_link "#{@contract.name}"
    page.should_not have_content "Edit document details"
    page.should have_content "#{@contract.find_value_for("employee_first_name")} #{@contract.find_value_for("employee_last_name")}"
  end

  scenario 'Managing team' do
    other = FactoryGirl.create(:user)
    @employee.organisations.first.employees = other
    other_member = Member.for(other, @employee.organisations.first)
    sign_in @employee
    page.should_not have_content "Manage Team"
    position1 = FactoryGirl.create(:position, member: @employee.active_employee_membership, organisation: @employee.first_organisation)
    position2 = FactoryGirl.create(:position, member: other_member, parent_position: position1, organisation: @employee.first_organisation)
    click_link "Home"
  end

  context "Onboarding status", js: true do
    background do
      @employment.update_attributes(creator: @employer.active_membership, onboarding_status: Member::OnboardingStatus::DETAILS)
      sign_in @employee
    end

    scenario "With a contract selected" do
      within '.employee-onboarding-steps .list' do
        expect(page).to have_no_css('a')
      end

      @employment.update_column(:onboarding_status, Member::OnboardingStatus::RECIPIENT_SIGNATURE)
      visit employee_dashboard_index_path
      expect(page).to have_css('.employee-onboarding-steps .list:nth-child(6) a')
    end

    scenario "Without a contract" do
      @employment.update_column(:onboarding_status, Member::OnboardingStatus::RECIPIENT_SIGNATURE)
      visit employee_dashboard_index_path

      ["Employee details entered by employer", "Employee details", "Employee tax details", "Employee super details"].each do |step|
        expect(page).to have_content(step)
      end

      ["Contract selection", "Contract finalisation",  "Contract completion - sender signature", "Contract completion - recipient signature"].each do |step|
        expect(page).to have_no_content(step)
      end
    end
  end
end
