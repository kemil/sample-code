require 'spec_helper'

describe EmployeeFilesController do

  describe :index do
    context :not_logged_in do
      it 'redirects the user to sign in' do
        get :index
        response.should redirect_to new_user_session_path
      end
    end

    context :logged_in do
      before do
        @user  = create(:user_with_organisation)
        @user2 = create(:user)
        @user3 = create(:user)
        organisation           = @user.organisations.first
        organisation.employees = @user2
        organisation.employees = @user3
        @user3.memberships.first.update_attributes(accepted: true, managers_list: @user2.memberships.first.id)
        @member = Member.for(@user2, organisation)
      end

      context "employer logged in" do
        before do
          sign_in(@user)
        end

        it 'returns 200 success' do
          get :index
          response.status.should == 200
        end
      end

      context "manager logged in" do
        before do
          sign_in @user2
        end

        it 'returns 200 success' do
          get :index
          response.status.should == 200
        end
      end

      context "worker logged in" do
        it "redirects to the employee dashboard" do
          sign_in @user3
          get :index
          response.should redirect_to employee_dashboard_index_path
        end
      end
    end
  end

end
