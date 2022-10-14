class Employee < Patron
  HR_CAMPUS_MAP = {
    "um_ann-arbor" => "UMAA",
    "um_flint" => "UMFL",
    "um_dearborn" => "UMDB"
  }

  def campus_code
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

  def email_type
    "work"
  end

  def umich_address_type
    "work"
  end

  def hr_list
    hr = role == "sponsored_affiliate" ? @data["umichsponsorshipdetail"] : @data["umichhr"]
    raise if hr.nil? # there always has to be hrdata
    ldap_fields(hr)
  end

  def hr_criteria(hr_item)
    case role
    when "faculty"
      hr_item.jobCategory == "Faculty"
    when "temporary_staff"
      hr_item.jobCategory == "Staff" && hr_item.regTemp == "T"
    when "sponsored_affiliate"
      true
    when "retiree"
      hr_item.jobCategory == "Faculty"
    end
  end

  def hr_filtered
    hr_list.filter do |hr_item|
      hr_criteria(hr_item)
    end
  end

  def hr_data
    library_job = hr_filtered.find { |x| x.deptId =~ /^47/ }
    library_job || hr_filtered.first
  end
end
