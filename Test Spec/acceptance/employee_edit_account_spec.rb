require 'acceptance/acceptance_helper'

feature 'Employee edit account', %q{
  In order to edit my profile details
  As an Employee
  I want an Account page
}, acceptance: true do

  background do
    @employer = FactoryGirl.create(:user_with_organisation)
    @employee = FactoryGirl.create(:user, employee_of: @employer.organisations.first)
  end

  scenario 'Employee editing their account' do
    # Given I am an employee
    sign_in @employee
    # When I click on the 'My Profile' link in the menu bar
    click_link "My Profile"
    # Then I should see my account page
    current_path.should == edit_user_registration_path
    # And it should be on the My Profile tab by default.
    page.should have_css(".active", :text => "My Profile")
    visit profile_employee_dashboard_index_path
    click_link "Click here to complete your profile"
    # Then I should see my account page
    current_path.should == edit_user_registration_path
    # And it should be on the My Profile tab by default.
    page.should have_css(".active", :text => "My Profile")
    fill_in "Known as", :with => "MyNickname"
    click_button "Update"
    page.should have_content "MyNickname"
    page.should have_content "Your profile was updated."
  end

  scenario 'Updating the employees password' do
    sign_in @employee
    click_link "Reset Password"
    page.should_not have_content "Billing Info"
    page.should_not have_content "Company Profile"
    fill_in "Current Password", with: "password"
    fill_in "New password", with: "newpassword"
    click_button "Reset"
    page.should have_content "Dashboard"
    click_link "Sign out"
    page.should have_content "Sign In"
    fill_in "Email", with: @employee.email
    fill_in "Password", with: "newpassword"
    click_button "Sign in"
    page.should have_content "Dashboard"
  end

  scenario 'Employee Admin (Employer) editing their account' do
    # Given I am an employee who has been made an employee admin
    @employee.memberships.first.set_admin(true)
    sign_in @employee
    # When I click on My Profile
    click_link "My Profile"
    # Then I should see my profile
    page.should have_content "My Profile"
  end

  scenario 'Cannot update membership details' do
    sign_in @employee
    visit edit_membership_path(@employee.active_membership)

    within '#employment-details' do
      expect(page).to have_no_content 'Employing entity'
      expect(page).to have_no_content 'Probation length'
      expect(page).to have_content 'Company email'
    end
  end
end
