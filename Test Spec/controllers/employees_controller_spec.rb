require 'spec_helper'

describe EmployeesController do

  describe :edit do
    before :each do
      @employer = FactoryGirl.create(:user_with_organisation)
      sign_in @employer
      @employee = FactoryGirl.create(:user)
      @employer.organisations.first.employees = @employee
      @random_user = FactoryGirl.create(:user)
      controller.stub :current_user => @employer
    end

    it "returns 200 success" do
      get :edit, id: @employee.id, membership_id: @employee.memberships.first.id
      response.status.should == 200
    end

    it "redirects to employments path" do
      get :edit, id: @random_user.id, membership_id: create(:member).id
      response.should redirect_to memberships_path
    end
  end

  describe :update do
    before :each do
      @employer = FactoryGirl.create(:user_with_organisation)
      sign_in @employer
      @employee = FactoryGirl.create(:user, first_name: "John")
      @employer.organisations.first.employees = @employee
      @membership = @employee.memberships.first
      User.stub :find => @employee
      Member.stub :find => @membership
    end

    it "redirects after updating successfully" do
      put :update, id: @employee.id, member: { first_name: "James" }, membership_id: @membership.id
      response.should redirect_to membership_path(@employee.memberships.first)
      @membership.reload.first_name.should == "James"
    end

    it "creates a notification" do
      Notification.should_receive(:own_details_updated_for_member).with(@employee.memberships.first)
      put :update, id: @employee.id, member: { first_name: "James" }, membership_id: @membership.id
    end

    context "failed to update" do
      it "renders 'edit' if failing to update attributes" do
        @membership.stub :update_attributes => false
        put :update, id: @employee.id, member: { first_name: "James" }, membership_id: @membership.id
        response.status.should == 200
        response.should render_template :edit
      end
    end
  end
end
