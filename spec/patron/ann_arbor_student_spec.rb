describe Patron::AnnArborStudent do
  before(:each) do
    @patron = json_fixture("emcard_student.json")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
    @current_schedule_double = instance_double(CurrentSchedule, default_expiry_date: Date.parse("2022-01-31"), includable_term?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double, current_schedule: @current_schedule_double)
  end
  context "#term(termcode)" do
    it "returns the correct term for a given term code" do
      expect(subject.term("2520")).to eq("W25")
      expect(subject.term("2530")).to eq("SP25")
      expect(subject.term("2540")).to eq("SS25")
      expect(subject.term("2550")).to eq("SU25")
      expect(subject.term("2560")).to eq("F25")
      expect(subject.term("2570")).to eq("W26")
    end
  end
  context "#user_group" do
    it "is 04 for undergrads" do
      # acadCareer
      # acadProg
      expect(subject.user_group).to eq("04")
    end
    it "is 03 for gradudate students" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=GENG")
      expect(subject.user_group).to eq("03")
    end
    it "is 03 for candidates" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=GRAC")
      expect(subject.user_group).to eq("03")
    end
  end
  context "#statistic_category" do
    it "is UN for Undergrads" do
      expect(subject.statistic_category).to eq("UN")
    end
    it "is CD for candidates" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=GRAC")
      expect(subject.statistic_category).to eq("CD")
    end
    it "is GR for gradudate students" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=GENG")
      expect(subject.statistic_category).to eq("GR")
    end
    it "is correct when for an example with a program number" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=AENG")
      @patron["umichaaacadprogram"][0].sub!("acadProg=00007", "acadProg=01364")
      expect(subject.statistic_category).to eq("GR")
    end
  end
  context "#includable?" do
    it "is true when there is a registered for a current term" do
      allow(@current_schedule_double).to receive(:includable_term?) do |termcode|
        termcode == "SP22" # this the registered one
      end
      expect(subject.includable?).to eq(true)
    end
    it "is true when NRGS, but is in grad school" do
      @patron["umichaacurrenttermstatus"][1].sub!("RGSD", "NRGS")
      @patron["umichaacurrenttermstatus"][1].sub!("acadCareer=UENG", "acadCareer=GRAC")
      expect(subject.includable?).to eq(true)
    end
    it "is false when not registered for any term" do
      @patron["umichaacurrenttermstatus"][1].sub!("RGSD", "NRGS")
      expect(subject.includable?).to eq(false)
    end
    it "is false when registered for a term that is not a current term" do
      allow(@current_schedule_double).to receive(:includable_term?) do |termcode|
        termcode == "W24" # this will be later than Spring or Summer 2022
      end
      expect(subject.includable?).to eq(false)
    end
    it "is false when there's an invalid acadCareer" do
      @patron["umichaaacadprogram"][0].sub!("acadCareer=UENG", "acadCareer=NOTACAREER")
      expect(subject.includable?).to eq(false)
    end
  end
end
