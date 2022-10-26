xdescribe Patron::Retiree do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @patron["umichinstroles"][1] = "Retiree"
    @patron["umichhr"][0].sub!("jobCategory=Staff", "jobCategory=Faculty")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  context "#user_group" do
    it "returns 01" do
      expect(subject.user_group).to eq("01")
    end
  end
  context "#campus_code" do
    it "comes from HR data" do
      expect(subject.campus_code).to eq("UMAA")
      expect(subject.base_inst_role["campus"]).to be_nil
    end
  end
  context "#job_description" do
    it "returns a job_description from HR data" do
      expect(subject.job_description).to eq("Library Info Tech - AIM (470430)")
    end
  end
  context "#hr_data" do
    it "returns appropriate object for retiree" do
      expect(subject.hr_data.jobCategory).to eq("Faculty")
    end
  end
  context "#statistic_category" do
    it "returns RF" do
      expect(subject.statistic_category).to eq("RF")
    end
  end
  context "#email_type" do
    it "returns work" do
      expect(subject.email_type).to eq("work")
    end
  end
  context "#umich_address_type" do
    it "returns work" do
      expect(subject.email_type).to eq("work")
    end
  end
  context "#includable?" do
    it "is true for retired faculty" do
      expect(subject.includable?).to eq(true)
    end
    it "is false for retired staff (and other non faculty)" do
      @patron["umichhr"][0].sub!("jobCategory=Faculty", "jobCategory=Staff")
      expect(subject.includable?).to eq(false)
    end
  end
end
