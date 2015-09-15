require 'spec_helper'

describe BankAccount do
  it { should belong_to(:member) }

  describe "required fields" do
    it { should validate_presence_of(:statement_text) }
    it { should validate_presence_of(:account_name) }
    it { should validate_presence_of(:account_number) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:bsb) }
    it { should ensure_length_of(:account_name).is_at_most(32) }
  end

  describe "setting primary account" do
    before do
      @member = FactoryGirl.create(:member)
    end

    context "members first account" do
      it "sets the bank account as a primary account" do
        @member.bank_accounts << BankAccount.new(account_name: "Boom", account_number: "123", bsb: "456", amount: "100", statement_text: "Woop")
        @member.bank_accounts.first.should be_primary_account
      end
    end

    context "members additional account" do
      before do
        @member.bank_accounts << BankAccount.new(account_name: "Boom", account_number: "123", bsb: "456", amount: "100", statement_text: "Woop")
        @member.bank_accounts << BankAccount.new(account_name: "Boom", account_number: "789", bsb: "101112", amount: "100", statement_text: "Woop")
      end

      it "keeps the original bank account as a primary account" do
        @member.bank_accounts.first.should be_primary_account
      end

      it "creates a new bank account that is a non-primary account" do
        @member.bank_accounts.last.should_not be_primary_account
      end

      context "deleted primary account" do
        it "sets the next created bank account as a primary account" do
          @member.bank_accounts.first.destroy
          @member.bank_accounts.first.should be_primary_account
        end
      end

      context "deleting all accounts" do
        it "removes all bank accounts" do
          @member.bank_accounts.destroy_all
          @member.bank_accounts.count.should == 0
        end
      end
    end
  end

  describe 'Validate account number' do
    let(:valid_formats) { ['11111-B1', '111-111', '111-1111', '111 111', '111 1111'] }
    let(:invalid_formats) { ['11111-BB', '1ABC', 'A111 111'] }
    let(:bank_account) { build(:bank_account) }

    it 'validates format of account number' do
      valid_formats.each do |account_number|
        bank_account.account_number = account_number
        expect(bank_account).to be_valid
      end

      invalid_formats.each do |account_number|
        bank_account.account_number = account_number
        expect(bank_account).to have(1).error_on(:account_number)
      end
    end
  end
end
