require 'spec_helper'

describe EmployeeBenefitsController do
  before :each do
    organisation = create(:organisation, :owner)
    @user = organisation.owner
    @user.memberships.first.update_attribute(:accepted, true)
    @account = organisation.account
    2.times{ organisation.callback_tokens << CallbackToken.create }
    sign_in @user
  end

  describe "#index" do
    before do
      @employee_benefits = [mock_model(EmployeeBenefit, value: "test-code"), mock_model(EmployeeBenefit, value: "test-code")]

      controller.stub(:current_account).and_return(@account)
      controller.stub(:current_user).and_return(@user)
      controller.stub(:check_trial_expiration)
      @account.stub(:inactive?)
      EmployeeBenefit.stub_chain(:active, :by_company).and_return(@employee_benefits)
    end

    context "with active account" do
      it "finds employee benefits" do
        @account.should_receive(:inactive?).and_return(false)
        EmployeeBenefit.stub_chain(:active, :by_company).and_return(@employee_benefits)
        get :index
      end

      it "assigns the employee benefits list to @employee_benefits" do
        get :index
        assigns[:employee_benefits].should == @employee_benefits
      end
    end

    context "with inactive account" do
      it "creates organisation notifications" do
        @account.should_receive(:inactive?).and_return(true)
        OrganisationNotification.should_receive(:employee_benefits_accessed_by_member)
        get :index
      end
    end

    it "responds with index template" do
      get :index
      response.should render_template(:index)
    end
  end
end
