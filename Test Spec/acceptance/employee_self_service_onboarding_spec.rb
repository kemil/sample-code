require 'acceptance/acceptance_helper'

feature 'Employee self-service onboarding', %q{
  In order to setup the employment information easily
  As an employee
  I want to have a self-service onboarding process
}, acceptance: true do

  let(:employer) { create(:user_with_organisation) }
  let(:organisation) { employer.first_organisation }
  let!(:employing_entity) { create(:employing_entity, organisation: organisation) }
  let!(:employee) { create(:user, employee_of: organisation) }
  let(:member) { employee.memberships.first }
  let(:superannuation_fund) { create(:superannuation_fund) }

  before do
    sign_in employee
    member.update_attribute :creator, employer.active_membership
    organisation.update_attribute :superannuation_fund_id, superannuation_fund.id
  end

  context 'Personal Details' do
    before do
      visit employee_onboarding_path(:personal_details)
    end

    scenario 'Render form' do
      expect(page).to have_content("Personal")
      expect(page).to have_content("Emergency contact")
      expect(page).to have_content("Bank details")
    end

    scenario 'Validate failed', js: true do
      fill_in "Account name", with: ""
      fill_in "BSB", with: ""
      fill_in "Account number", with: ""

      click_button 'Next'
      expect(page).to have_content 'Please review the problems below:'
      expect(page).to have_content "can't be blank"
    end

    scenario 'Enter personal details successfully', js: true do
      fill_in 'Date of birth', with: '01/01/1999'
      find('#member_gender_male').click
      fill_in 'Address line 1', with: '123 Ave'
      fill_in 'Personal mobile number', with: '123123123'
      fill_in 'Contact Name', with: 'John'

      fill_in 'Account name', with: 'Account'
      fill_in 'BSB', with: '111111'
      fill_in 'Account number', with: '111111'

      click_button 'Next'
      expect(page).to have_content 'Tax declaration'

      expect(member.reload.date_of_birth.to_s(:dmy)).to eq '01/01/1999'
      expect(member.address.line_1).to eq '123 Ave'
      expect(member.bank_accounts.first).to have_attributes(
        account_name: 'Account',
        account_number: '111111',
        bsb: '111111')

      expect(member.onboarding_status).to eq(Member::OnboardingStatus::EMPLOYEE_DETAILS)
    end
  end

  context 'Tax Declaration', js: true do
    before do
      visit employee_onboarding_path(:tax_declaration)
    end

    scenario 'Validate failed', js: true do
      click_button 'Next'
      expect(page).to have_content 'Please sign the declaration form'

      sign_signature '#user_signature_pad'
      fill_in 'Tax file number', with: '111'
      sign_signature '#tax-signature-pad'
      click_button 'Next'
      expect(page).to have_content 'Please review the problems below:'
      expect(page).to have_content 'is invalid'
    end

    scenario 'Turn on/off tax options' do
      check I18n.t('tax_declaration.tax_resident')
      expect(find('#tax_declaration_tax_free')[:disabled]).to eq 'false'
      expect(find('#tax_declaration_senior_tax_offset')[:disabled]).to eq 'true'
      expect(find('#tax_declaration_dependent_tax_offset')[:disabled]).to eq 'true'

      check I18n.t('tax_declaration.tax_free')
      expect(find('#tax_declaration_senior_tax_offset')[:disabled]).to eq 'false'
      expect(find('#tax_declaration_dependent_tax_offset')[:disabled]).to eq 'false'
    end

    scenario 'Declare Tax successfully' do
      fill_in 'Tax file number', with: '111111111'
      sign_signature '#tax-signature-pad'

      click_button 'Next'
      expect(page).to have_content("We're almost done with your onboarding")
      expect(member.reload.tax_declaration.tax_file_number).to eq '111111111'
      expect(member.reload.onboarding_status).to eq(Member::OnboardingStatus::EMPLOYEE_TAX_DETAILS)
    end
  end

  context 'Work eligibility and superannuation funds', js: true do
    context "User is Australian resident" do
      before do
        member.tax_declaration.update_attribute :tax_resident, true
        visit employee_onboarding_path(:work_eligibility)
      end

      scenario "No work eligibility section" do
        expect(page).to_not have_content("Australian work eligibility")
      end

      scenario "Submit successfully with employee's superannuation fund", js: true do
        choose 'My choice of superannuation fund'
        fill_in "Fund name", with: "SOS FUND"
        sign_signature "#signature-pad-wrapper"

        click_button "Finished"

        expect(page).to have_content "You have finished the onboarding process"
        expect(member.reload.onboarding_status).to eq(Member::OnboardingStatus::EMPLOYEE_SUPER_DETAILS)
      end
    end

    context "User is non-resident", js: true do
      before do
        Delayed::Worker.delay_jobs = true
        member.tax_declaration.update_attribute :tax_resident, false
        visit employee_onboarding_path(:work_eligibility)
      end

      after do
        Delayed::Worker.delay_jobs = false
      end

      scenario "Work eligibility section" do
        expect(page).to have_content("Australian work eligibility")
      end

      scenario "Submit successfully" do
        fill_in "Passport number", with: "123123"
        fill_in "Passport expiry date", with: "14/02/2014"
        select "Australia", from: "Passport issue country"
        select "Student (8104/5)", from: "Visa type"
        fill_in "Visa expiry date", with: "14/02/2015"

        choose "Employer's superannuation fund"
        sign_signature "#signature-pad-wrapper"

        click_button "Finished"

        expect(page).to have_content "You have finished the onboarding process"
        expect(member.reload.onboarding_status).to eq(Member::OnboardingStatus::EMPLOYEE_SUPER_DETAILS)
        expect(Delayed::Job.last.name).to match /employee_onboarding_completed/
      end
    end
  end
end
