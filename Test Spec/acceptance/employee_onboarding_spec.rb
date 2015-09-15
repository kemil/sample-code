require 'acceptance/acceptance_helper'

feature 'Employee onboarding', %q{
  In order to onboard new employee
  As an employer
  I want to create contracts with new employee onboarding information
}, acceptance: true do
  let(:email) { Faker::Internet.email }
  let(:employer) { create(:user_with_organisation) }
  let(:organisation) { employer.first_organisation }
  let!(:employing_entity) { create(:employing_entity, organisation: organisation) }
  let!(:authorising_signatory) { create(:authorising_signatory,
                                        organisation: organisation,
                                        requester: employer.active_membership,
                                        member: signatory_employee.active_membership) }
  let!(:signatory_employee) { create(:user, employee_of: organisation) }
  let(:signature_string) { 'data:image/png;base64,' + Base64.encode64(File.read(Rails.root.join('spec/fixtures/signature.png'))).gsub!("\n", '') }
  let!(:document) { create(:document, organisation: organisation, sample: true, disabled: false, onboarding: true) }
  let!(:block_variable) { create(:block_variable, :sender_signature_pad, sample_contract: document, initial_value: "data:image/png;base64,default_value") }
  let!(:recipient_signature) { create(:block_variable, :recipient_signature_pad, sample_contract: document, initial_value: '') }
  let!(:section) { create(:section, contract: document, optional: false) }
  let!(:block) { create(:block, section: section, optional: true, visible: true, content: "###{block_variable.id}## ###{recipient_signature.id}##") }
  let!(:manager) { create(:user, employee_of: organisation) }

  before do
    authorising_signatory.update_column(:signature, "data:image/pngbase64abc")
    authorising_signatory.representatives << employer.active_membership
    sign_in employer
  end

  context 'Both party sign' do
    scenario 'new user onboarding', js: true do
      user_onboarding_steps

      page.find(:css, "#contract_deliver_method_email").click
      expect(page).to have_content("Email Message")
      expect(page).to have_content("auth_token")

      # Print contract
      page.find(:css, "#contract_deliver_method_hard_copy").click
      expect(page).to have_content("Print contract")

      # Email contract
      click_button "Email contract"
      expect(page).to have_content("Please select a sending signatory")

      # Testing using authorising signatory
      select signatory_employee.active_membership.name, from: "Sending signatory"
      wait_for_ajax
      expect(page.find(:css, ".signature")['src']).to have_content(authorising_signatory.signature)

      # Testing signing signature
      select employer.memberships.last.name, from: "Sending signatory"
      expect(page).to have_content("Sign your signature")
      page.execute_script("$('.hidden-signature-input').val('#{signature_string}');")
      click_button "Sign document"
      wait_for_ajax
      expect(page.find(:css, ".signature")['src']).to have_content(signature_string)

      # Email contract
      click_button "Email contract"
      expect(page).to have_content("Please accept the terms of use")

      check "I have read and understood the disclaimer and accept the terms of use"
      click_button "Email contract"

      expect(page).to have_content("You have sent the contract successfully")
      expect(current_path).to eq dashboard_index_path
      expect(@onboarding_member.reload.onboarding_status).to eq(Member::OnboardingStatus::SENDER_SIGNATURE)

      sign_out employer
      new_document = organisation.documents.where(sample: false).last
      visit document_path(new_document, auth_token: @onboarding_user.authentication_token)

      expect_signature_certificate

      click_link "Sign and Accept"
      check "agree"
      page.execute_script "$('.signature-pad-variable').remove()"
      VariableValue.where(contract_id: new_document, block_variable_id: recipient_signature).update_all(value: signature_string)
      click_button "Sign and Accept"
      expect(page).to have_content "Commence your onboarding"
      expect(current_path).to eq(employee_onboarding_path(:personal_details))
      expect(@onboarding_member.reload.onboarding_status).to eq(Member::OnboardingStatus::RECIPIENT_SIGNATURE)
    end
  end

  context 'Only sender sign' do
    let!(:block) { create(:block, section: section, optional: true, visible: true, content: "###{block_variable.id}##") }
    before { Delayed::Worker.delay_jobs = true }
    after { Delayed::Worker.delay_jobs = false }

    scenario 'new user onboarding', js: true do
      document.contract_type.update_column(:signature_flow, SignatureFlow::ONLY_SENDER_SIGNS)
      user_onboarding_steps

      check "I have read and understood the disclaimer and accept the terms of use"
      page.find(:css, "#contract_deliver_method_email").click
      expect(page).to have_content("auth_token")

      # Testing using authorising signatory
      select signatory_employee.active_membership.name, from: "Sending signatory"
      new_document = organisation.documents.where(sample: false).last
      wait_for_ajax
      click_button "Sign and Finalise"
      signature_value = VariableValue.where(contract_id: new_document.id, block_variable_id: block_variable.id).last
      signature_value.update_column(:value, signature_string)
      expect(page).to have_content("You have sent the contract successfully")
      expect(@onboarding_member.reload.onboarding_status).to eq(Member::OnboardingStatus::SENDER_SIGNATURE)
    end
  end

  scenario 'Incomplete onboarding employee status', js: true do
    user_onboarding_steps
    visit dashboard_index_path

    within '.incomplete-onboarding-employee' do
      expect(page).to have_content @onboarding_member.name
      expect(page).to have_content "Onboarding started by #{employer.memberships.last.name}"
      expect(page).to have_content "(4/8)"

      expect(@onboarding_member.received_contracts).to be_present
      with_confirm(true) { click_link 'Delete' }
      expect(@onboarding_member.received_contracts.reload).to be_blank
    end
  end

  scenario 'Resume incomplete onboarding user', js: true do
    # Given the organisation has an incomplete onboarding employee that selected a contract
    employee = create(:member, role: organisation.roles.employee, creator: employer.active_membership, onboarding_status: Member::OnboardingStatus::CONTRACT_SELECTION)

    # When I visit the dashboard
    visit dashboard_index_path

    # Then I should see that employee although the contract has been deleted
    within '.incomplete-onboarding-employee' do
      expect(page).to have_content employee.name

      # And resume link should redirect them to the page for selecting a new contract
      within '.onboarding-actions' do
        expect(page).to have_selector "a[href='#{employee_onboarding_path(:select_contract)}']"
      end
    end
  end

  scenario 'Edit employee details when clicking back button from selecting a contract', js: true do
    visit employee_onboarding_path(:details)

    fill_details_form
    click_button "Continue"
    expect(page).to have_content("Select an employment contract")

    @onboarding_user = User.find_by_email(email)
    expect(@onboarding_user.memberships.count).to eq(1)

    page.execute_script('window.history.back()')
    fill_in "First name", with: "Apple"
    fill_in "Job title", with: 'Developer'
    select manager.memberships.first.name, from: 'Primary manager'
    click_button "Continue"

    expect(page).to have_content("Select an employment contract")

    expect(@onboarding_user.memberships.count).to eq(1)
    @onboarding_member = @onboarding_user.reload.memberships.first
    expect(@onboarding_member.first_name).to eq 'Apple'
    expect(@onboarding_member.job_title).to eq 'Developer'
  end

  scenario 'Skip selecting a contract step', js: true do
    Delayed::Worker.delay_jobs = true
    visit employee_onboarding_path(:details)

    # details
    fill_details_form
    click_button "Continue"

    click_link 'Skip this step'
    expect(page).to have_content 'Your employee will receive an invitation email soon'
    onboarding_user = User.find_by_email(email)
    expect(onboarding_user.memberships.first.onboarding_status).to eq(Member::OnboardingStatus::RECIPIENT_SIGNATURE)
    expect(Delayed::Job.last.name).to match /new_employee_email/

    Delayed::Worker.delay_jobs = false
  end

  def user_onboarding_steps
    visit employee_onboarding_path(:details)

    # details
    fill_details_form
    click_button "Continue"

    expect(page).to have_content("Select an employment contract")
    within '.contract-type h5' do
      expect(page).to have_no_content("Employment Contracts")
    end
    @onboarding_user = User.find_by_email(email)
    @onboarding_member = @onboarding_user.memberships.first
    expect(@onboarding_member.onboarding_status).to eq(Member::OnboardingStatus::DETAILS)
    expect(@onboarding_member.organisation_id).to eq(organisation.id)

    # select_contract
    page.find(:css, "#contract_id_#{document.id}").click
    click_button "Continue"
    expect(page).to have_content("To start editing the document")
    expect(@onboarding_member.reload.onboarding_status).to eq(Member::OnboardingStatus::CONTRACT_SELECTION)

    # edit_contract
    click_link "Continue"
  end

  def fill_details_form
    fill_in "First name", with: "Firstname"
    fill_in "Last name", with: "Lastname"
    fill_in "Personal email", with: email
    select manager.memberships.first.name, from: 'Primary manager'

    fill_in "Start date", with: Date.today.to_s(:dmy)
    fill_in "Work hours", with: "20"
  end

  def expect_signature_certificate
    expect(page).to have_content 'Sender'
    expect(page).to have_content 'Time of dispatch'
    expect(page).to have_content 'Place of dispatch'
    expect(page).to have_content 'Time of signature'
    expect(page).to have_content 'Place of signature'
    expect(page).to have_content 'Recipient'
    expect(page).to have_content 'Time of receipt'
    expect(page).to have_content 'Place of receipt'
  end
end
