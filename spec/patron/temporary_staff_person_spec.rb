describe Patron::TemporaryStaffPerson do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @patron["umichinstroles"][1] = "TemporaryStaffAA"
    @patron["umichhr"][0].sub!("regTemp=R", "regTemp=T")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  context "#user_group" do
    it "returns 14" do
      expect(subject.user_group).to eq("14")
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
    it "returns TS" do
      expect(subject.statistic_category).to eq("TS")
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
  context "exclude_reason" do
    it "is nil when valid" do
      expect(subject.exclude_reason).to be_nil
    end
    it "is invalid_job_category when not staff" do
      @patron["umichhr"][0].sub!("jobCategory=Staff", "jobCategory=Invalid")
      expect(subject.exclude_reason).to eq("job_category_not_staff")
    end
    it "is not_regular_employee when not regTemp is not R" do
      @patron["umichhr"][0].sub!("regTemp=T", "regTemp=R")
      expect(subject.exclude_reason).to eq("not_temporary_employee")
    end
  end
end
