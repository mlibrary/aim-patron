describe Patron::StaffPerson do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  context "#user_group" do
    it "returns 02" do
      expect(subject.user_group).to eq("02")
    end
    it "retuns 01 for a GEO" do
      @patron["umichhr"][0].sub!("jobcode=101904", "jobcode=205000")
      expect(subject.user_group).to eq("01")
    end
  end
  context "#campus_code" do
    it "comes from HR data" do
      @patron["umichhr"][0].sub!("UM_ANN-ARBOR", "UM_FLINT")
      expect(subject.campus_code).to eq("UMFL")
      expect(subject.base_inst_role["campus"]).to eq("UMAA")
    end
  end
  context "#job_description" do
    it "returns a job_description from HR data" do
      expect(subject.job_description).to eq("Library Info Tech - AIM (470430)")
    end
  end
  context "#hr_data" do
    it "returns appropriate object for staff" do
      expect(subject.hr_data.jobCategory).to eq("Staff")
    end
  end
  context "#statistic_category" do
    it "returns ST" do
      expect(subject.statistic_category).to eq("ST")
    end
    it "retuns GE for a GEO" do
      @patron["umichhr"][0].sub!("jobcode=101904", "jobcode=205000")
      expect(subject.statistic_category).to eq("GE")
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
end
