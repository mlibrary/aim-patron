describe Patron::Faculty do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @patron["umichinstroles"][1] = "FacultyAA"
    @patron["umichhr"][0].sub!("jobCategory=Staff", "jobCategory=Faculty")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  context "#user_group" do
    it "returns 14" do
      expect(subject.user_group).to eq("01")
    end
  end
  context "#campus_code" do
    it "comes from HR data" do
      @patron["umichhr"][0].sub!("UM_ANN-ARBOR", "UM_FLINT")
      expect(subject.campus_code).to eq("UMFL")
    end
  end
  context "#includable?" do
    it "is true when it has a Faculty job category" do
      expect(subject.includable?).to eq(true)
    end
    it "is false when there is no appropriate job category" do
      @patron["umichhr"][0].sub!("jobCategory=Faculty", "jobCategory=Staff")
      expect(subject.includable?).to eq(false)
    end
  end
  context "#exclude_reason" do
    it "is nil when it has a Faculty job category" do
      expect(subject.exclude_reason).to be_nil
    end
    it "is false when there is no appropriate job category" do
      @patron["umichhr"][0].sub!("jobCategory=Faculty", "jobCategory=Staff")
      expect(subject.exclude_reason).to eq("no_faculty_job_category")
    end
  end

  context "#job_description" do
    it "returns a job_description from HR data" do
      expect(subject.job_description).to eq("Library Info Tech - AIM (470430)")
    end
  end
  context "#hr_data" do
    it "returns appropriate object for staff" do
      expect(subject.hr_data.jobCategory).to eq("Faculty")
    end
  end
  context "#statistic_category" do
    it "returns FA" do
      expect(subject.statistic_category).to eq("FA")
    end
    it "handles an emeritus" do
      # Professor Emeritus
      @patron["umichhr"][0].sub!("jobcode=101904", "jobcode=201070")
      expect(subject.statistic_category).to eq("EM")
    end
    it "handles an adjunct faculty" do
      # Adjunct Faculty
      @patron["umichhr"][0].sub!("jobcode=101904", "jobcode=201030")
      expect(subject.statistic_category).to eq("AF")
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
