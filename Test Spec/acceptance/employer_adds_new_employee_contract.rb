require 'acceptance/acceptance_helper'

feature 'Employer adding new employee contract', %q{
  In order to add new contracts to an existing employee
  As an employer
  I want to have HR workflow for adding contracts
} do

  let!(:employer) { create(:user_with_organisation) }
  let!(:authorising_signatory) { create(:authorising_signatory,
                                        organisation: organisation,
                                        requester: employer.active_membership,
                                        member: signatory_employee.active_membership) }
  let!(:signatory_employee) { create(:user, employee_of: organisation) }

  let!(:employee) { create(:user, employee_of: employer.first_organisation) }
  let!(:contract_type) { create(:contract_type) }
  let!(:contract) { create(:document, contract_type: contract_type, sample: true) }
  let!(:sending_signatory_employee) { create(:user, employee_of: employer.first_organisation) }

  background do
    sign_in employer
  end

  scenario "cannot add new document to self" do
    visit membership_path(employer.active_membership)
    within ".documents-module" do
      expect(page).to_not have_content("Add New")
    end
  end

  context "sending signatory" do
    background do
      prepare_contract

      # Email contract
      click_button "Email contract"
      expect(page).to have_content("Please select a sending signatory")
    end

    scenario "authorising signatory on contract signature" do
      # Testing using authorising signatory
      select signatory_employee.active_membership.name, from: "Sending signatory"
      wait_for_ajax
      expect(page.find(:css, ".signature")['src']).to have_content(authorising_signatory.signature)

      accept_term_of_use
      click_button "Email contract"
      expect(page).to have_content("You have sent the contract successfully")
    end

    scenario "self-signed contract before sending" do
      select employer.name, from: "Sending signatory"
      expect(page).to have_content("Sign your signature")
      page.execute_script("$('.hidden-signature-input').val('data:image/pngbase64mysignature');")
      click_button "Sign document"
      wait_for_ajax
      expect(page.find(:css, ".signature")['src']).to have_content('data:image/pngbase64mysignature')

      accept_term_of_use
      click_button "Email contract"
      expect(page).to have_content("You have sent the contract successfully")
    end

    scenario "sending signatory before sending" do
      select sending_signatory_employee.active_membership.name, from: "Sending signatory"

      accept_term_of_use
      click_button "Email contract"
      expect(page).to have_content("You have sent the contract successfully")
    end
  end

  def prepare_contract
    visit membership_path(employee.active_membership)
    within ".documents-module" do
      click_link "Add New"
    end

    find_field(contract.name).click
    click_button 'Continue'

    within "#document-edit .actions" do
      click_link "Continue"
    end
  end

  def accept_term_of_use
    # Email contract
    click_button "Email contract"
    expect(page).to have_content("Please accept the terms of use")

    check "I have read and understood the disclaimer and accept the terms of use"
  end
end
