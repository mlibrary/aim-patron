describe Patron do
  before(:each) do
    @patron = JSON.parse(File.read("./spec/fixtures/emcard_staff.json"))
  end
  subject do
    described_class.new(@patron)
  end
  it "returns record_type" do
    # this is static
    expect(subject.record_type).to eq("PUBLIC")
  end
  it "returns external_id" do
    # this is static
    expect(subject.record_type).to eq("SIS")
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
  it "returns a campus_code" do
    expect(subject.campus_code).to eq("UMAA")
  end
  it "returns a user_group" # do
  #  expect(subject.user_group).to eq("02")
  # end
  it "returns a status_date"
  it "returns an expiry_date"
  it "returns a purge_date"
  it "returns a job_description" do
    expect(subject.job_description).to eq("Library Info Tech - AIM (470430)")
  end
  it "returns statistic_category"
end
