require 'spec_helper'

describe Agreement do

  describe :associations do
    it { should belong_to(:organisation) }
    it { should belong_to(:subscription_plan) }
  end

  context "Agreement#first_payment_date" do
    it "should return October 30th if agreement was created on Sep 30th and SubscriptionPlan is billed each month" do
      subscription_plan = create(:subscription_plan)
      subject.subscription_plan = subscription_plan

      subject.created_at = Date.parse('30th Sept 2000')

      subject.first_payment_date.should == 'October 30th'
    end

    it "should return " do
      subscription_plan = create(:subscription_plan, renewal_period: 12)
      subject.subscription_plan = subscription_plan

      subject.created_at = Date.parse('30th Sept 2000')

      subject.first_payment_date.should == (subject.created_at + 1.year).strftime("%d %b %Y")
    end
  end
end
