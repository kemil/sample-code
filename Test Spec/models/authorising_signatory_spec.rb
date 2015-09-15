require 'spec_helper'

describe AuthorisingSignatory do
  describe "authorising signatory uniqueness for an organisation" do
    let(:authorising_signatory) { create(:authorising_signatory) }

    it "allows a new authorising signatory to be created for the organisation" do
      new_signatory = build(:authorising_signatory, organisation: authorising_signatory.organisation)
      expect(new_signatory).to be_valid
    end

    it "doesn't allow duplicate authorising signatory be created for an organisation" do
      duplicated = authorising_signatory.clone
      duplicated.id = nil
      expect(duplicated).to_not be_valid
      expect(duplicated).to have(1).errors_on(:member_id)
    end
  end
end
