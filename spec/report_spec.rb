describe Report do
  let(:staff_data) do
    json_fixture("emcard_staff.json")
  end
  let(:staff_person) do
    Patron::StaffPerson.new(data: staff_data)
  end
  let(:sponsored_affiliate) do
    start_date_str = Date.today.prev_day.strftime("%m/%d/%Y")
    end_date_str = Date.today.next_day.strftime("%m/%d/%Y")
    staff_data["umichsponsorshipdetail"] = [
      "{campus=UM_ANN-ARBOR}:{deptId=99999}:{deptGroup=SOME_DEPT_GROUP}:{deptDescription=SOME DEPARTMENT DESCRIPTION}:{deptGroupDescription=School of Something}:{deptVPArea=PRVST_EXC_VP_ACA_AFF}:{umichSponsorAdmin=sponsoruniqname}:{umichSponsorRequestor=otheruniqname}:{umichSponsorReason=Researchers}:{umichSponsorStartDate=#{start_date_str}}:{umichSponsorEndDate=#{end_date_str}}:{umichSponsorshipCn=111-111-11111111111111111-111}"
    ]
    Patron::SponsoredAffiliate.new(data: staff_data)
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

  it "includes a header with all of the column names" do
    subject
    expect(@file_handle.string).to include("action")
    expect(@file_handle.string).to include("umid")
    expect(@file_handle.string).to include("uniqname")
    expect(@file_handle.string).to include("campus")
    expect(@file_handle.string).to include("user_group")
    expect(@file_handle.string).to include("statistic_category")
    expect(@file_handle.string).to include("sponsor_reason")
    expect(@file_handle.string).to include("exclude_reasons")
  end
  context "#load" do
    it "writes the word LOAD for a staff person, umid, user_group, user_statistic" do
      subject.load(staff_person)
      expect(@file_handle.string).to include("LOAD")
      expect(@file_handle.string).to include("emcard")
      expect(@file_handle.string).to include("99991111")
      expect(@file_handle.string).to include("ann_arbor")
      expect(@file_handle.string).to include("staff")
      expect(@file_handle.string).to include("staff")
    end
    it "includes a sponsored affiliate reason when there is one" do
      subject.load(sponsored_affiliate)
      expect(@file_handle.string).to include("researchers")
    end

    it "increments the counters when valid" do
      subject.load(staff_person)
      expect(Report.metrics.statistic_category.get(name: "staff", script_type: "test")).to eq(1)
      expect(Report.metrics.patron_kind.get(name: "staff_person", script_type: "test")).to eq(1)
      expect(Report.metrics.user_group.get(name: "staff", script_type: "test")).to eq(1)
      expect(Report.metrics.campus.get(name: "ann_arbor", script_type: "test")).to eq(1)
      expect(Report.metrics.sponsor_reason.values).to eq({})
    end
    it "increments the sponsor reason when there is one" do
      subject.load(sponsored_affiliate)
      expect(Report.metrics.sponsor_reason.get(name: "researchers", script_type: "test")).to eq(1)
    end
  end

  context "#skip" do
    it "includes columns in the report" do
      skipped_person = Patron::Skipped.new(data: staff_data, exclude_reasons: ["reason1", "reason2"])
      subject.skip(skipped_person)
      expect(@file_handle.string).to include("SKIP")
      expect(@file_handle.string).to include("emcard")
      expect(@file_handle.string).to include("99991111")
      expect(@file_handle.string).to include("reason1,reason2")
    end
  end

  context "exclude_reason metric" do
    it "is incremeneted when user a user is a test user" do
      test_user = staff_data
      test_user["uid"] = ["ststv"]
      Yabeda.with_tags(script_type: "test") do
        Patron.for(test_user)
      end
      expect(Report.metrics.exclude_reason.get(name: "test_user", script_type: "test")).to eq(1)
    end
    it "is incremented when a user is skipped for some other reason" do
      staff_data["umichhr"][0].sub!("jobCategory=Staff", "jobCateogry=INVALID")
      Yabeda.with_tags(script_type: "test") do
        Patron.for(staff_data)
      end
      expect(Report.metrics.exclude_reason.get(name: "job_category_not_staff", script_type: "test")).to eq(1)
    end
  end
end
