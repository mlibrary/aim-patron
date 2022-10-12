describe Patron do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @name_double = instance_double(Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  it "returns record_type" do
    # this is static
    expect(subject.record_type).to eq("PUBLIC")
  end
  it "returns external_id" do
    # this is static
    expect(subject.external_id).to eq("SIS")
  end
  it "returns a primary_id" do
    expect(subject.primary_id).to eq("emcard")
  end
  it "returns a first_name" do
    expect(subject.first_name).to eq("Emily")
  end
  it "returns a last_name" do
    expect(subject.last_name).to eq("Card")
  end
  it "returns a middle_name" do
    expect(subject.middle_name).to eq("O")
  end
  it "returns true if a middle name exists" do
    expect(subject.middle_name?).to eq(true)
  end
  it "returns a campus_code" do
    expect(subject.campus_code).to eq("UMAA")
  end
  xit "returns a user_group" do
    expect(subject.user_group).to eq("02")
  end
  it "returns a status_date"
  it "returns an expiry_date"
  it "returns a purge_date"
  it "returns a job_description" do
    expect(subject.job_description).to eq("Library Info Tech - AIM (470430)")
  end
  it "returns statistic_category"
  context "#base_inst_role" do
    it "returns the correct heirarchical inst role" do
      @patron["umichinstroles"].push("FacultyAA")
      expect(subject.base_inst_role["role"]).to eq("faculty")
      expect(subject.base_inst_role["campus"]).to eq("UMAA")
    end
  end
end
