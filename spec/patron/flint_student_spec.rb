describe Patron::FlintStudent do
  before(:each) do
    @patron = json_fixture("emcard_flint_student.json")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
    @current_schedule_double = instance_double(CurrentSchedule, default_expiry_date: Date.parse("2022-01-31"), includable_term?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double, current_schedule: @current_schedule_double)
  end

  context "#term(acad_program)" do
    it "returns the correct values" do
      expect(subject.term("201910")).to eq("F18")
      expect(subject.term("201920")).to eq("W19")
      expect(subject.term("201930")).to eq("SP19")
      expect(subject.term("201940")).to eq("SU19")
      expect(subject.term("202010")).to eq("F19")
      expect(subject.term("202020")).to eq("W20")
    end
  end
  context "#user_group" do
    it "is 04 for undergrads" do
      @patron["umichflntcurrenttermstatus"][0].sub!("classStanding=GR", "classStanding=FR")
      expect(subject.user_group).to eq("04")
    end
    it "is 03 for gradudate students" do
      expect(subject.user_group).to eq("03")
    end
  end
  context "#statistic_category" do
    it "is UN for Undergrads" do
      @patron["umichflntcurrenttermstatus"][0].sub!("classStanding=GR", "classStanding=FR")
      expect(subject.statistic_category).to eq("UN")
    end
    it "is GR for gradudate students" do
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
    it "is false when not registered for any term" do
      @patron["umichflntcurrenttermstatus"][0].sub!("registered=Y", "registered=N")
      expect(subject.includable?).to eq(false)
    end
    it "is false when registered for a term that is not a current term" do
      allow(@current_schedule_double).to receive(:includable_term?) do |termcode|
        termcode == "W24" # this will be later than Spring or Summer 2022
      end
      expect(subject.includable?).to eq(false)
    end
    it "is false when there's no CurrentTermStatus" do
      @patron.delete("umichflntcurrenttermstatus")
      expect(subject.includable?).to eq(false)
    end
  end
  context "#exclude_reason" do
    it "is nil when there is a registered for a current term" do
      allow(@current_schedule_double).to receive(:includable_term?) do |termcode|
        termcode == "SP22" # this the registered one
      end
      expect(subject.exclude_reason).to be_nil
    end
    it "is not_registered when not registered for any term" do
      @patron["umichflntcurrenttermstatus"][0].sub!("registered=Y", "registered=N")
      expect(subject.exclude_reason).to eq("not_registered")
    end
    it "is false when registered for a term that is not a current term" do
      allow(@current_schedule_double).to receive(:includable_term?) do |termcode|
        termcode == "W24" # this will be later than Spring or Summer 2022
      end
      expect(subject.exclude_reason).to eq("not_registered")
    end
    it "is false when there's no CurrentTermStatus" do
      @patron.delete("umichflntcurrenttermstatus")
      expect(subject.exclude_reason).to eq("not_registered")
    end
  end
end
