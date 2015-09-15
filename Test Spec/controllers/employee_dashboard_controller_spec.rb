require 'spec_helper'

describe EmployeeDashboardController do

  describe :index do
    describe :signed_in do
      before :each do
        @employer = create(:user_with_organisation)
        @employee = create(:user)
        @employer.organisations.first.employees = @employee
        sign_in(@employee)
      end

      it "returns a 200 status" do
        get :index
        response.status.should == 200
      end

      it 'assigns the membership' do
        get :index
        assigns[:membership].should == @employee.active_employee_membership
      end
    end

    describe :not_signed_in do
      it "directs to sign in" do
        get :index
        response.should redirect_to new_user_session_url
      end
    end
  end

  describe :profile do
    describe :signed_in do
      it "returns a 200 status" do
        employer = FactoryGirl.create(:user_with_organisation)
        employee = FactoryGirl.create(:user)
        employer.organisations.first.employees = employee
        sign_in(employee)
        get :profile
        response.status.should == 200
      end
    end

    describe :not_signed_in do
      it "directs to sign in" do
        get :profile
        response.should redirect_to new_user_session_url
      end
    end
  end

end
