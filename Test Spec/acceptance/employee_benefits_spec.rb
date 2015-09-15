require 'acceptance/acceptance_helper'

feature 'Employee Benefits', %q{
  As a trial or paid user,
  I  should be able to have access to Employee Benefits.
}, acceptance: true do

  background do
    @employer = FactoryGirl.create(:user_with_organisation)
    2.times { @employer.first_organisation.callback_tokens << CallbackToken.create }
    @employer.first_organisation.save
    sign_in @employer
  end

  scenario "Viewing Employee Benefits" do
    benefit = FactoryGirl.create(:employee_benefit)
    visit employee_benefits_path
    page.should have_content "Employee Benefits"
    page.should have_content benefit.company
    page.should have_content benefit.description
    page.should have_content "Valid until #{benefit.end_date.strftime("%d %b %Y")}"
  end

  scenario "Expired organisation accounts - owners and employers" do
    #Given my trial has expired
    #And I am an Owner or Employer
    @organisation = @employer.organisations.first
    @organisation.current_agreement.update_attribute :created_at, 30.days.ago
    # When I am on the Employee Benefits page
    visit dashboard
    click_link "Benefits"
    current_path.should == "/employee_benefits"
    #Then I should see the message: "Your trial period has expired. Please upgrade your account"
    page.should have_content "Your trial period has expired. Please upgrade your account"
    # And "Please upgrade your account" is a link to /account/manage_account
    page.should have_xpath('//a', text: "Please upgrade your account")
  end

  scenario "Expired organisation accounts - employees" do
    # Given my trial has expired
    @organisation = @employer.organisations.first
    @organisation.current_agreement.update_attribute :created_at, 30.days.ago

    # And I am Employee "Scott Summers"
    employee = FactoryGirl.create(:user, first_name: "Scott", last_name: "Summers")
    @employer.first_organisation.assign_added_employee(employee, true)

    sign_out @employer
    sign_in employee
    # When I am on the Employee Benefits page
    visit employee_benefits_path
    # Then I should see the message: "Your organisation's trial period has expired and its subscription plan will need to be upgraded to have Employee Benefits available again"
    page.should have_content "Your organisation's trial period has expired and its subscription plan will need to be upgraded to have Employee Benefits available again"
    # sign_out employee

    # sign_in @employer
    # # And an Employer notification should be created with the message: "Scott Summers just tried accessing Employee Benefits. Please upgrade your account to enable these Employee Benefits"
    # page.should have_content "#{employee.active_membership.name} just tried accessing Employee Benefits. Please upgrade your account to enable these Employee Benefits"
    # # And "Please upgrade your account" is a link to /account/manage_account
    # page.should have_xpath('//a', text: "Please upgrade your account")
  end

  scenario "Organisation accounts with extra trial days" do
    Timecop.freeze("15/05/2013")
    # Given I registered for a free trial on 01/04/2013
    @organisation = @employer.organisations.first
    @organisation.current_agreement.update_attribute :created_at, Date.parse("01/04/2013")
    # And I entered a PromoCode that gave me an extra 30 free trial days
    discount_code = FactoryGirl.create(:discount_code, extra_trial_days: 30)
    @organisation.update_attribute :discount_code, discount_code

    # This should reload the `current_account`
    # current_account.organisation.discount_code is not present
    # @organisation.discount_code is present
    sign_out @employer
    sign_in @employer
    # When I am on the Employee Benefits page
    visit dashboard
    benefit = FactoryGirl.create(:employee_benefit)
    visit employee_benefits_path
    # And the current date is 15/05/2013
    # Then I should see the list of Employee Benefits
    page.should have_content benefit.company
    page.should have_content benefit.description
    page.should have_content "Valid until #{benefit.end_date.strftime("%d %b %Y")}"
    Timecop.return
  end
end
