class Employee < Patron
  HR_CAMPUS_MAP = {
    "um_ann-arbor" => "UMAA",
    "um_flint" => "UMFL",
    "um_dearborn" => "UMDB"
  }

  def campus
    HR_CAMPUS_MAP[hr_data.campus.downcase]
  end

  def user_group
    case role
    when "faculty"
      "01"
    when "staff"
      "02"
    when "temporary_staff"
      "14"
    when "sponsored_affiliate"
      "01"
    when "retiree"
      "01"
    end
  end

  def job_description
    "#{hr_data.deptDescription} (#{hr_data.deptId})"
  end

  def hr_data
    hr = role == "sponsored_affiliate" ? @data["umichsponsorshipdetail"] : @data["umichhr"]
    raise if hr.nil? # there always has to be hrdata
    hr_list = ldap_fields(hr)

    filtered = hr_list.filter do |x|
      case role
      when "faculty"
        x.jobCategory == "Faculty"
      when "staff"
        x.jobCategory == "Staff" && x.regTemp == "R"
      when "temporary_staff"
        x.jobCategory == "Staff" && x.regTemp == "T"
      when "sponsored_affiliate"
        true
      when "retiree"
        x.jobCategory == "Faculty"
      end
    end
    library_job = filtered.find { |x| x.deptId =~ /^47/ }
    library_job || filtered.first
  end
end
