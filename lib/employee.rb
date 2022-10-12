class Employee < Patron
  HR_CAMPUS_MAP = {
    "um_ann-arbor" => "UMAA",
    "um_flint" => "UMFL",
    "um_dearborn" => "UMDB"
  }
  def campus
    HR_CAMPUS_MAP[hr_data.campus.downcase]
  end

  def hr_data
    role = base_inst_role["role"]
    hr = role == "sponsored_affiliate" ? @data["umichsponsorshipdetail"] : @data["umichhr"]
    raise if hr.nil? # there always has to be hrdata
    hr_list = ldap_fields(hr)

    filtered = hr_list.filter do |x|
      case role
      when "staff"
        x.jobCategory == "Staff" && x.regTemp == "R"
      when "temporary_staff"
        x.jobCategory == "Staff" && x.regTemp == "T"
      when "faculty"
        x.jobCategory == "Faculty"
      when "retiree"
        x.jobCategory == "Faculty"
      when "sponsored_affiliate"
        true
      end
    end
    library_job = filtered.find { |x| x.deptId =~ /^47/ }
    library_job || filtered.first
  end
end
