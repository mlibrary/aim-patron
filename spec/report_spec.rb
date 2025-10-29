describe Report do
  let(:staff_person) do
    Patron::StaffPerson.new(data: json_fixture("emcard_staff.json"))
  end
  before(:each) do
    @file_handle = StringIO.new
    Report.configure_yabeda! unless Yabeda.already_configured?
  end
  after(:each) do
    Yabeda.reset!
  end
  subject do
    described_class.new(fh: @file_handle, script_type: "test")
  end

  context "#load" do
    it "writes the word LOAD for a staff person, umid, user_group, user_statistic" do
      subject.load(staff_person)
      expect(@file_handle.string).to include("LOAD")
      expect(@file_handle.string).to include("emcard")
      expect(@file_handle.string).to include("99991111")
      expect(@file_handle.string).to include("UMAA")
      expect(@file_handle.string).to include("02")
      expect(@file_handle.string).to include("ST")
    end
    it "increments the counters" do
      subject.load(staff_person)
      expect(Report.metrics.statistic_category.get(name: "ST", script_type: "test")).to eq(1)
      expect(Report.metrics.patron_kind.get(name: "staff_person", script_type: "test")).to eq(1)
    end
  end
end
