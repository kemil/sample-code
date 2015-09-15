require 'acceptance/acceptance_helper'

feature 'Employee Files', %q{
  As an employer
  I want to see my employees
  So that I can view my employee files and documents
}, acceptance: true do

  background do
    @owner = FactoryGirl.create(:user_with_organisation)
    sign_in @owner
  end

  scenario "Viewing employee table", js: true do
    employee = FactoryGirl.create(:user)
    @owner.organisations.first.employees = employee
    employee.memberships.first.update_attributes(active: true, accepted: true)
    visit employee_files_path
    page.should have_content "Employee Files"
    page.should have_content "Add Employee"
    find_link("Add Employee").should be_visible
    page.should have_content "Employee"
    page.should have_content "Position"
    page.should have_content "Status"
    page.should have_content employee.memberships.last.name
    page.should_not have_content "There are currently no employee files to display. Employee files are created when an employment document is sent for signature. Alternatively, click on the Add Employee button to create a new employee file to add to your records."
  end

  scenario "Viewing admin employees", js: true do
    employer = FactoryGirl.create(:user)
    @owner.organisations.first.employees = employer
    @owner.organisations.first.assign_employer(employer)
    employer.memberships.first.update_attributes(active: true, accepted: true)
    visit employee_files_path
    page.should have_content "Employee Files"
    page.should have_content "Add Employee"
    find_link("Add Employee").should be_visible
    page.should have_content "Employee"
    page.should have_content "Position"
    page.should have_content "Status"
    page.should_not have_content "There are currently no employee files to display. Employee files are created when an employment document is sent for signature. Alternatively, click on the Add Employee button to create a new employee file to add to your records."
    page.should have_content "#{employer.memberships.last.name}"
  end

  scenario "Deleting employees", js: true do
    employee = create(:user, employee_of: @owner.active_membership.organisation)
    employee.memberships.first.update_attributes(active: true, accepted: true)

    visit employee_files_path
    within "#employee-table tbody tr#member-#{employee.id}" do
      click_link "Delete"
    end

    expect(page).to have_content("You can proceed by confirming the name of the selected employee (#{employee.memberships.last.name})")

    page.execute_script(
      "$('.delete-member-form').validate({
        rules: {
          name: {
            equalTo: '#expectation_name'
          }
        },
        messages: {
          name: {
            equalTo: 'The employee name does not match. Make sure you are using the correct upper and lower case'
          }
        },
        errorPlacement: function(error, element) {
          error.insertAfter('p.help-block');
        }
      });"
    )

    sleep(1);

    fill_in "name", with: "unmatched name"
    click_button "Delete"
    expect(page).to have_content "The employee name does not match. Make sure you are using the correct upper and lower case"

    fill_in "name", with: employee.memberships.last.name
    click_button "Delete"

    expect(page).to have_content "Deleted employee #{employee.memberships.last.name} successfully"
  end

  context 'Filter by statuses' do
    let(:organisation) { @owner.first_organisation }
    let(:active_employee) { create(:user, employee_of: organisation) }
    let(:pending_employee) { create(:user, employee_of: organisation) }
    let(:archived_employee) { create(:user, employee_of: organisation) }

    before do
      active_employee.memberships.first.update_attributes(active: true, accepted: true)
      pending_employee.memberships.first.update_attributes(active: true, accepted: false)
      archived_employee.memberships.first.archive
    end

    scenario 'Filter by Terminated', js: true do
      visit employee_files_path

      within '.status-filter' do
        find('label', :text => 'Terminated').click
      end

      within '#employees' do
        expect(page).to_not have_content active_employee.memberships.last.name
        expect(page).to have_content archived_employee.memberships.last.name
        expect(page).to_not have_content pending_employee.memberships.last.name
      end
    end
  end

  context 'Pagination' do
    let(:organisation) { @owner.first_organisation }
    let!(:employees) { create_list(:user, 26, employee_of: @owner.first_organisation) }

    scenario 'Paginate employee files', js: true do
      Member.update_all({active: true, accepted: true})

      visit employee_files_path

      expect(page).to have_css('.pagination')
    end
  end

  scenario 'Employer can delete employees except for self', js: true do
    visit employee_files_path
    within "#employee-table tbody tr#member-#{@owner.id}" do
      expect(page).to have_no_content 'Delete'
    end
  end
end
