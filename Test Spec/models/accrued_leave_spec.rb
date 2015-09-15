require 'spec_helper'

describe AccruedLeave do
  it { should belong_to :payslip }
  it { should validate_presence_of(:payslip) }

  describe ".create_from_keypay" do
    let(:payslip) { create(:payslip) }
    let(:keypay_accrued_leaves) { build_list(:keypay_accrued_leave, 2) }

    it "creates AccruelLeave from a KeyPay AccruedLeaves" do
      expect {
        AccruedLeave.create_from_keypay(payslip.accrued_leaves, keypay_accrued_leaves)
      }.to change { AccruedLeave.count }.by(2)
    end
  end

  describe '#display?' do
    let(:accrued_leave) { create(:accrued_leave) }

    context 'Without the leave category exists' do
      it 'returns false' do
        expect(accrued_leave.display?).to be_false
      end
    end

    context 'With the leave category exists' do
      it 'returns true if the accrued leave is not be hidden from payslip nor balance' do
        leave_category = double(:leave_category, hide_balance: false, hide_from_payslip: false)
        allow(accrued_leave).to receive(:leave_category).and_return(leave_category)

        expect(accrued_leave.display?).to be_true
      end

      it 'returns false otherwise' do
        leave_category = double(:leave_category, hide_balance: true)
        allow(accrued_leave).to receive(:leave_category).and_return(leave_category)

        expect(accrued_leave.display?).to be_false
      end
    end
  end

  describe ".create_from_xero" do
    let(:payslip) { create(:payslip) }
    let(:xero_accrued_leave) { build(:xero_accrued_leave) }

    it "creates AccruelLeave from Xero AccruedLeaves" do
      expect {
        payslip.accrued_leaves.create_from_xero(xero_accrued_leave)
      }.to change { payslip.accrued_leaves.count }.by(1)
    end
  end
end
