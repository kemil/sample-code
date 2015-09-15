require 'spec_helper'
include ActionView::Helpers::NumberHelper

describe Account do
  let(:account) { create(:account) }
  let(:free_subscription_plan) { create(:free_subscription_plan) }
  let(:trial_account) { create(:account_with_organisation, subscription_plan: free_subscription_plan) }
  let(:standard_account) { create(:account_with_organisation, subscription_plan: create(:subscription_plan)) }

  context "Protected attributes" do
    it { should allow_mass_assignment_of :active }
    it { should allow_mass_assignment_of :code }
    it { should allow_mass_assignment_of :subscription_plan }
    it { should allow_mass_assignment_of :subscription_plan_id }
  end

  describe :associations do
    it { should belong_to(:organisation) }
    it { should belong_to(:subscription_plan) }
  end

  describe :scopes do
    it "Account#with_free_subscription should return only free accounts" do
      Account.destroy_all
      free_account_one = create(:trial_account, organisation_id: nil)
      free_account_two = create(:trial_account, organisation_id: nil)
      standard_account = create(:account, organisation_id: nil)

      Account.with_free_subscription.count.should == 2
    end
  end

  describe :charge_for_plan do
    context :legacy do
      it "returns the plans price" do
        @organisation           = create(:organisation)
        account.update_attribute(:organisation_id, @organisation.id)
        account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, legacy: true, minimum_users: 0)

        account.send(:charge_for_plan, account.subscription_plan).should == 100
      end
    end

    context :non_legacy do
      it "returns the plan charge with discount" do
        @organisation           = create(:organisation)
        account.update_attribute(:organisation_id, @organisation.id)
        account.stub(:users_count).and_return(1)
        account.organisation.subscription_plans << create(:subscription_plan, price: 1000, minimum_amount: 50, minimum_users: 1)
        account.stub(:apply_discount).with(1000).and_return(14)
        account.send(:charge_for_plan, account.subscription_plan).should == 14
      end
    end
  end

  describe :invoice_price_in_dollars_incl_gst do
    before :each do
      @organisation           = create(:organisation)
      account.update_attribute(:organisation_id, @organisation.id)
    end

    it "should return [organisation's active users] x [subscripton plan price] if organisation's employees exceeds Subscription Plan's employee limit (incl. GST)" do
      @organisation.employees = [create(:user), create(:user)]
      account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, minimum_users: 1)
      account.organisation.employees = create(:user)
      account.organisation.members.each do |employee|
        employee.update_attribute(:accepted, true)
      end

      account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((@organisation.active_members.count * @organisation.current_subscription_plan.price_in_cents * Account::GST / 100), :precision =>2)
    end

    it "should return the Subscription Plan's minimum amount if organisation's employees < Subscription Plan's employee limit (incl. GST)" do
      MIN_AMOUNT = 50
      account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, minimum_users: 2)

      account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((MIN_AMOUNT * Account::GST), :precision =>2)
    end

    it "should return with GST Subscription Pan's minimum amount if organisation's employees == Subscription Plan's employee limit (incl. GST)" do
      @organisation.employees = create(:user)
      account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, minimum_users: 2)
      account.organisation.employees = create(:user)

      account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((50 * Account::GST), :precision =>2)
    end

    it "includes a discount percentage (incl. GST)" do
      account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, minimum_users: 2)
      discount_code = FactoryGirl.create(:discount_code, percent: true, percentage: 50)
      account.organisation.discount_code = discount_code
      account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((25 * Account::GST), :precision =>2)
    end

    it "doesn't include the discount percentage if they have already received an invoice (incl. GST)" do
      account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 50, minimum_users: 2)
      discount_code = FactoryGirl.create(:discount_code, percent: true, percentage: 50)
      @organisation.set_discount(discount_code.value)
      @organisation.current_agreement.invoices << FactoryGirl.create(:invoice, agreement: @organisation.current_agreement)
      account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((50 * Account::GST), :precision =>2)
    end

    context :legacy do
      it "returns the legacy price inclusive of GST" do
        account.organisation.subscription_plans << create(:subscription_plan, price: 100, legacy: true, minimum_amount: 0, minimum_users: nil)
        account.invoice_price_in_dollars_incl_gst(account.subscription_plan).should == number_with_precision((100), precision: 2)
      end
    end
  end

  describe :minimum_charge do
    context :legacy do
      it "returns the plan price" do
        @organisation           = create(:organisation)
        account.update_attribute(:organisation_id, @organisation.id)
        account.organisation.subscription_plans << create(:subscription_plan, price: 100, legacy: true, minimum_amount: 0, minimum_users: nil)
        account.minimum_charge(account.subscription_plan).should == 100
      end
    end

    context :non_legacy do
      before :each do
        @organisation           = create(:organisation)
        account.update_attribute(:organisation_id, @organisation.id)
        account.organisation.subscription_plans << create(:subscription_plan, price: 100, minimum_amount: 15, minimum_users: 2)
      end

      it "returns the minimum amount for user count less then the plans minimum users number" do
        account.stub(:users_count).and_return(1)
        account.minimum_charge(account.subscription_plan).should == 15
      end

      it "returns 0 if the minimum users is less than the user count" do
        account.stub(:users_count).and_return(3)
        account.minimum_charge(account.subscription_plan).should == 0
      end
    end
  end

  describe :users_count do
    let!(:organisation) { create(:organisation) }
    let!(:role) { create(:role, organisation: organisation) }
    let!(:member1) { create(:member, organisation: organisation, accepted: true, role: role) }
    let!(:member2) { create(:member, organisation: organisation, accepted: true, role: role, independent_contractor: true) }
    let!(:member3) { create(:member, organisation: organisation, accepted: true, role: role,system: true) }

    it "returns the active non-contractor and system members for the organisation" do
      account.organisation = organisation
      account.users_count.should == 1
    end
  end

  describe "kind of SubscriptionPlan" do
    context "when it's a free subscription" do
      it "#trial_subscription should return true" do
        trial_account.should be_trial_subscription
      end
    end

    context "when it's not a free subscription" do
      it "#trial_subscription should return false" do
        account.should_not be_trial_subscription
      end
    end
  end

  describe "expiration" do
    context "when a FREE trial account expires" do
      it "Account#expired? should return true" do
        trial_account.organisation.current_agreement.update_column(:created_at, 50.days.ago)
        trial_account.should be_expired
      end
    end

    context "when a FREE trial account is not expired" do
      it "Account#expired? should return false" do
        trial_account.should_not be_expired
      end
    end

    context "when a FREE trial account with additional trial days is not expired" do
      it "Account#expired? should return false" do
        trial_account.organisation.current_agreement.update_column(:created_at, 40.days.ago)
        extra_15_trial_days = create(:extra_15_trial_days)
        trial_account.organisation.discount_code = extra_15_trial_days

        trial_account.should_not be_expired
      end
    end
  end

  describe :expire_today do
    it "should return true when expiration date equals the current day" do
      trial_account.organisation.current_agreement.update_column(:created_at, 30.days.ago)

      trial_account.reload.should be_expire_today
    end
  end

  describe :inactive do
    it "returns true if a trial account is expired" do
      trial_account.organisation.current_agreement.update_column(:created_at, 50.days.ago)

      trial_account.should be_inactive
    end

    it "returns false if a trial account is not expired" do
      trial_account.should_not be_inactive
    end

    it "returns false if an account is on a paid plan" do
      standard_account.should_not be_inactive
    end
  end

  describe :expiration_date do
    it "returns the expiration_date including the first day of use" do
      Timecop.freeze("01/10/2013")
      account.stub_chain(:organisation, :current_agreement, :created_at).and_return(Date.current)
      account.stub_chain(:subscription_plan, :expiration_interval).and_return(30.days)
      account.expiration_date.should == Date.parse("30/10/2013")
      Timecop.return
    end
  end

  describe :days_left do
    before :each do
      Timecop.freeze("01/10/2013")
    end

    after :each do
      Timecop.return
    end

    it "returns the number of days left in the trial including the first day" do
      trial_plan = build(:free_subscription_plan)
      account = build(:account_with_organisation, subscription_plan: trial_plan)
      account.days_left.should == 30
    end

    it "returns the number of days left in the trial if created at is in the past" do
      trial_plan = build(:free_subscription_plan)
      account = build(:account_with_organisation, subscription_plan: trial_plan)
      account.organisation.current_agreement.update_column(:created_at, 10.days.ago)
      account.days_left.should == 20
    end
  end
end
