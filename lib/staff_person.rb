class StaffPerson < Employee
  def user_group
    "02"
  end

  def statistic_category
    "ST"
  end

  def hr_criteria(hr_item)
    hr_item.jobCategory == "Staff" && hr_item.regTemp == "R"
  end
end
