require 'acceptance/acceptance_helper'

feature 'Employee setting password', %q{
  In order to access my eHero account
  As an Employee
  I want to set my initial password
}, acceptance: true do

  background do
    # Given I am the employee of an organisation
    @employer = FactoryGirl.create(:user_with_organisation)
    @employee = User.new_without_password(email: "invited_employee@example.com", first_name: "John", last_name: "Doe")
    @employee.save!
    @employer.organisations.first.employees = @employee
    # And I just received an invite to set my account password
    @employee.invite_code.should_not be_false
  end

  after :each do
    @employer.delete
    @employee.delete
  end

  scenario 'Receiving an email link and creating an account' do
    # When I follow the link in the email
    visit accept_invite_url(@employee.memberships.last, invite: @employee.invite_code)
    # And I fill in the new fields correctly
    fill_in "Password", with: "validpassword"
    # And click "Submit"
    click_button "Create"
    # And I should be logged in
    page.should have_content "Sign out"
  end

  scenario 'Logging in for the first time via password-reset' do
    visit root_url
    click_on 'Sign in'
    click_link 'I forgot my password'
    fill_in 'user_email', with: 'invited_employee@example.com'
    click_on 'Continue'
    visit edit_user_password_url(reset_password_token: @employee.reload.reset_password_token)
    fill_in 'New password', with: 'valid password'
    click_button 'Update password'
    @employee.active_membership.accepted.should be_true
    @employee.reload.reset_password_token.should be_nil
    @employee.reload.invite_code.should be_nil
  end

end
