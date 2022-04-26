describe Patron do
  before(:each) do
    @patron = JSON.parse(File.read("./spec/fixtures/emcard_staff.json"))
  end
  subject do
    described_class.new(@patron)
  end
  it "returns a uniqname" do
    expect(subject.uniqname).to eq("emcard")
  end
end
