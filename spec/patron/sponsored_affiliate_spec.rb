describe Patron::SponsoredAffiliate do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
    @current_schedule_double = instance_double(CurrentSchedule, default_expiry_date: Date.today.next_year, default_purge_date: Date.today.next_year(2))
    @start_date = Date.today.prev_day.strftime("%D")
    @end_date = Date.today.next_day.strftime("%D")
    @sponsorship_info = "{campus=UM_ANN-ARBOR}:{deptId=99999}:{deptGroup=SOME_DEPT_GROUP}:{deptDescription=SOME DEPARTMENT DESCRIPTION}:{deptGroupDescription=School of Something}:{deptVPArea=PRVST_EXC_VP_ACA_AFF}:{umichSponsorAdmin=sponsoruniqname}:{umichSponsorRequestor=otheruniqname}:{umichSponsorReason=Researchers}:{umichSponsorStartDate=#{@start_date}}:{umichSponsorEndDate=#{@end_date}}:{umichSponsorshipCn=111-111-11111111111111111-111}"
    @patron["umichsponsorshipdetail"] = [@sponsorship_info]
  end
  subject do
    described_class.new(data: @patron, name: @name_double, current_schedule: @current_schedule_double)
  end
  context "#user_group" do
    it "returns 01" do
      expect(subject.user_group).to eq("01")
    end
  end
  context "#campus_code" do
    it "comes from HR data" do
      @patron["umichsponsorshipdetail"][0].sub!("UM_ANN-ARBOR", "UM_FLINT")
      expect(subject.campus_code).to eq("UMFL")
      expect(subject.base_inst_role["campus"]).to eq("UMAA")
    end
  end
  context "#job_description" do
    it "returns a job_description from HR data" do
      expect(subject.job_description).to eq("SOME DEPARTMENT DESCRIPTION (99999)")
    end
  end
  context "#hr_data" do
    it "returns appropriate object for sponsored affiliate" do
      expect(subject.hr_data.umichSponsorAdmin).to eq("sponsoruniqname")
    end
    xit "returns nil for UROP department" do
      @patron["umichsponsorshipdetail"][0].sub!("deptDescription=SOME DEPARTMENT DESCRIPTION", "deptDescription=LSA UG\: UROP")
      expect(subject.hr_data).to be_nil
    end
  end
  context "#statistic_category" do
    it "returns SA" do
      expect(subject.statistic_category).to eq("SA")
    end
    it "returns CN for contractors" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorReason=Researchers", "umichSponsorReason=Contractors")
      expect(subject.statistic_category).to eq("CN")
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
  xcontext "#includable?" do
    it "returns true for includable sponsor reason" do
      expect(subject.includable?).to eq(true)
    end
    it "returns false for non-includable sponsor reason" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorReason=Researchers", "umichSponsorReason=Other Guests")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for no sponsor start date" do
      @patron["umichsponsorshipdetail"][0].sub!("{umichSponsorStartDate=#{@start_date}}:", "")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for inincludable format of start date" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorStartDate=#{@start_date}", "umichSponsorStartDate=15102022")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for no sponsor end date" do
      @patron["umichsponsorshipdetail"][0].sub!("{umichSponsorEndDate=#{@end_date}}:", "")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for inincludable format of end date" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorEndDate=#{@end_date}", "umichSponsorEndDate=15102022")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for start date in the future" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorStartDate=#{@start_date}", "umichSponsorStartDate=#{@end_date}")
      expect(subject.includable?).to eq(false)
    end
    it "returns false for end date in the past" do
      @patron["umichsponsorshipdetail"][0].sub!("umichSponsorEndDate=#{@end_date}", "umichSponsorEndDate=#{@start_date}")
      expect(subject.includable?).to eq(false)
    end
  end
  xcontext "#expiry_date" do
    it "returns SponsorEndDate when it is before the regular expire date" do
      expect(subject.expiry_date).to eq(@end_date)
    end
    it "returns the regular expire date when the SponsorEndDate is later" do
      @end_date = Date.today.next_year(2)
      expect(subject.expiry_date).to eq(Date.today.next_year)
    end
  end
  xcontext "#purge_date" do
    it "returns SponsorEndDate + 2Y when the SponsorEndDate is before the regular expire date" do
      expect(subject.purge_date).to eq(@end_date.next_year(2))
    end
    it "returns the regular purge_date when the SponsorEndDate is later than the expire_date" do
      @end_date = Date.today.next_year(2)
      expect(subject.expiry_date).to eq(Date.today.next_year(2))
    end
  end
end
