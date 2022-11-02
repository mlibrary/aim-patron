describe Patron::Employee do
  before(:each) do
    @patron = json_fixture("emcard_staff.json")
    @name_double = instance_double(Patron::Name, first_name: "Emily", middle_name: "O", last_name: "Card", middle_name?: true)
  end
  subject do
    described_class.new(data: @patron, name: @name_double)
  end
  context "#hr_data" do
    it "returns the appropriate object for temporary Staff" do
      @patron["umichhr"][0].sub!("regTemp=R", "regTemp=T")
      @patron["umichinstroles"][1] = "TemporaryStaffAA"
      expect(subject.hr_data.jobCategory).to eq("Staff")
    end
    it "returns the appropriate object for faculty" do
      @patron["umichinstroles"][1] = "FacultyAA"
      @patron["umichhr"][0].sub!("Staff", "Faculty")
      expect(subject.hr_data.jobCategory).to eq("Faculty")
    end
    it "returns the sponsored affiliate info if the user is a sponsored affiliate" do
      @patron["umichinstroles"][1] = "SponsoredAffiliateAA"
      @patron["umichsponsorshipdetail"] = ["{campus=UM_ANN-ARBOR}:{deptId=9999999}:{deptGroup=SCHOOL_SOCIAL_WORK}:{deptDescription=School of Social Work}:{deptGroupDescription=School of Social Work}:{deptVPArea=SOMETHING}:{umichSponsorAdmin=someuniqname}:{umichSponsorRequestor=someuniqname}:{umichSponsorReason=Temporary Staff}:{umichSponsorStartDate=02/27/2019}:{umichSponsorEndDate=02/03/2023}:{umichSponsorshipCn=somestringofsomekind}"]
      @patron.delete("umhr")
      expect(subject.hr_data.campus).to eq("UM_ANN-ARBOR")
    end
    it "returns the library role if there are multiple and one is library" do
      @patron["umichhr"].unshift("{jobCategory=Staff}:{campus=UM_ANN-ARBOR}:{deptId=9999}:{deptGroup=UNIV_LIBRARY}:{deptDescription=Not Library IT}:{deptGroupDescription=University Library}:{deptVPArea=PRVST_EXC_VP_ACA_AFF}:{jobcode=101904}:{jobFamily=210}:{emplStatus=A}:{regTemp=R}:{supervisorId=99999}:{tenureStatus=NA}:{jobIndicator=P}")
      staff_person = Patron::StaffPerson.new(data: @patron, name: @name_double)
      expect(staff_person.hr_data.deptDescription).to eq("Library Info Tech - AIM")
    end
    it "returns the first hr if multiple and none are library" do
      @patron["umichhr"] = [
        "{jobCategory=Staff}:{campus=UM_ANN-ARBOR}:{deptId=9999}:{deptGroup=UNIV_LIBRARY}:{deptDescription=First Not Library IT}:{deptGroupDescription=University Library}:{deptVPArea=PRVST_EXC_VP_ACA_AFF}:{jobcode=101904}:{jobFamily=210}:{emplStatus=A}:{regTemp=R}:{supervisorId=99999}:{tenureStatus=NA}:{jobIndicator=P}",
        "{jobCategory=Staff}:{campus=UM_ANN-ARBOR}:{deptId=9999}:{deptGroup=UNIV_LIBRARY}:{deptDescription=Not Library IT}:{deptGroupDescription=University Library}:{deptVPArea=PRVST_EXC_VP_ACA_AFF}:{jobcode=101904}:{jobFamily=210}:{emplStatus=A}:{regTemp=R}:{supervisorId=99999}:{tenureStatus=NA}:{jobIndicator=P}"
      ]
      staff_person = Patron::StaffPerson.new(data: @patron, name: @name_double)
      expect(staff_person.hr_data.deptDescription).to eq("First Not Library IT")
    end
  end
end
