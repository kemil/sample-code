require 'spec_helper'

describe EmployeeDocumentsController do
  describe :index do
    it "redirects the employers to their dashboard" do
        owner = FactoryGirl.create(:user_with_organisation)
        sign_in owner
        get :index
        response.should redirect_to dashboard_index_path
    end

    context :employee do
      before do
        @owner = FactoryGirl.create(:user_with_organisation)
        @user = FactoryGirl.create(:user)
        @member = @owner.organisations.first.employees = @user
        sign_in @user
      end

      it "returns 200 success" do
        get :index
        response.status.should == 200
      end

      it "assigns the received documents" do
        controller.stub(:current_user).and_return(@user)
        @membership = @user.active_employee_membership
        @user.stub(:active_employee_membership).and_return(@membership)
        @membership.should_receive(:received_contracts).and_return([])
        get :index
        assigns[:received_documents].should == []
      end

      it "assigns the uploaded documents" do
        controller.stub(:current_user).and_return(@user)
        @membership = @user.active_employee_membership
        @user.stub(:active_employee_membership).and_return(@membership)
        @membership.should_receive(:uploads).and_return([])
        get :index
        assigns[:uploaded_documents].should == []
      end
    end
  end

  describe :policies do
    it "redirects the employers to their dashboard" do
      owner = FactoryGirl.create(:user_with_organisation)
      sign_in owner
      get :policies
      response.should redirect_to dashboard_index_path
    end

    context :employee do
      before do
        @owner = FactoryGirl.create(:user_with_organisation)
        @user = FactoryGirl.create(:user)
        @member = @owner.organisations.first.employees = @user
        sign_in @user
      end

      it "returns 200 success" do
        get :policies
        response.status.should == 200
      end

      render_views false
      it "assigns the policies" do
        account = @user.first_organisation.account
        controller.stub(:current_account).and_return(account)
        controller.stub(:current_organisation).and_return(account.organisation)
        policies = double(:policies)
        account.organisation.stub_chain(:contracts, :company_wide, :signed).and_return(policies)
        get :policies
        assigns[:documents].should == policies
      end
    end
  end

end
