require 'spec_helper'

describe AccountController do

  context "Redirecting non-owners" do
    it "redirects employees" do
      @user     = create(:user_with_organisation)
      @employee = create(:user)
      @user.organisations.first.employees = @employee
      sign_in(@employee)
      get :index
      response.should redirect_to employee_dashboard_index_path
    end

    it "returns 200 success for employers" do
      @user     = create(:user_with_organisation)
      @employer = create(:user)
      @user.first_organisation.assign_employer(@employer)
      sign_in(@employer)
      get :index
      response.should be_success
    end
  end

  context :owners do
    before(:each) do
      @user = FactoryGirl.create(:user_with_organisation)
      sign_in(@user)
    end

    describe :index do
      it "returns a 200 status" do
        get :index
        response.status.should == 200
      end
    end

    describe :update_company_profile do
      it "redirects to 'index'" do
        put :update_company_profile, :organisation => {}
        response.should redirect_to account_index_path
        flash[:notice].should == "Your company profile was updated."
      end

      it "renders 'index' if failed to update attributes" do
        controller.stub(:current_user).and_return(@user)
        organisation = @user.first_organisation
        organisation.stub(:update_attributes).and_return(false)
        controller.stub(:current_organisation).and_return(organisation)
        organisation.stub(:update_attributes).and_return(false)
        put :update_company_profile, :organisation => {}
        response.should render_template('index')
      end
    end

    describe :card_details do
      render_views false

      before :each do
        get :card_details, format: :js
      end

      it "sets the current user" do
        assigns[:current_user].should == @user
      end

      it "renders the card details partial" do
        response.should render_template :card_details
      end
    end

    describe :manage_account do
      it "returns a 200 status" do
        get :manage_account
        response.status.should == 200
      end

      context :new_subscription_present do
        render_views false

        it "assigns the new subscription" do
          subscription_param = double(:param)
          session[:new_subscription] = subscription_param
          subscription = double(:new_subscription)
          SubscriptionPlan.stub(:find).with(subscription_param).and_return(subscription)
          get :manage_account
          assigns[:new_subscription].should == subscription
        end

        it "sets the new subscription session to nil" do
          SubscriptionPlan.stub(:find)
          session[:new_subscription] = true
          get :manage_account
          session[:new_subscription].should be_nil
        end
      end
    end

    describe :reset_password do
      it "returns a 200 status" do
        get :reset_password
        response.status.should == 200
      end

      it "allows an employee to reset their password" do
        employee = create(:user)
        @user.first_organisation.employees = employee
        sign_out @user
        sign_in employee
        get :reset_password
        response.status.should == 200
      end
    end

    describe :update_password do

      it "renders 'reset_password' if there are any errors" do
        put :update_password, :user => { :current_password => "", :password => "password" }
        response.should render_template("reset_password")
      end

      it "redirects with a successful update" do
        User.stub(:find).and_return(@user)
        @user.stub(:update_with_password).and_return(true)
        put :update_password, :user => { :current_password => "current", :password => "password" }
        response.should redirect_to(dashboard_index_path)
      end

      it "renders 'reset_password'" do
        User.stub(:find).and_return(@user)
        @user.stub(:update_with_password).and_return(false)
        put :update_password, :user => { :current_password => "current", :password => "password" }
        response.should render_template :reset_password
      end

      it "renders reset if the current password is blank" do
        put :update_password, :user => { password: "newpassword" }
        response.should render_template :reset_password
      end

      it "renders reset if the password is blank" do
        put :update_password, :user => { current_password: "password" }
        response.should render_template :reset_password
      end

    end
  end

end
