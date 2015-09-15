require 'spec_helper'

describe EmployeePasswordController do

  before :each do
    @owner = FactoryGirl.create(:user_with_organisation)
    @employee = FactoryGirl.create(:user)
    @owner.organisations.first.employees = @employee
    sign_in(@employee)
  end

  describe :reset do
    it "returns a 200 status" do
      get :reset
      response.should be_success
      response.status.should == 200
    end
  end

  describe :update do
    it "redirects after updating" do
      put :update, :user => { current_password: "password", password: "newpassword" }
      response.should redirect_to employee_dashboard_index_url
      flash[:notice].should == "Your password was updated successfully."
    end

    it "renders reset if the current password is blank" do
      put :update, :user => { password: "newpassword" }
      response.should render_template :reset
    end

    it "renders reset if the password is blank" do
      put :update, :user => { current_password: "password" }
      response.should render_template :reset
    end

    it "renders reset if failed to update attributes" do
      User.stub :find => @employee
      @employee.stub :update_with_password => false
      put :update, :user => { current_password: "password", password: "newpassword" }
      response.should render_template :reset
    end
  end

end
