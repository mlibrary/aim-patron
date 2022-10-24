class Patron
  class TemporaryStaffPerson < Patron::Employee
    def user_group
    end

    def statistic_category
    end

    def hr_criteria(hr_item)
      hr_item.jobCategory == "Staff" && hr_item.regTemp == "T"
    end
  end
end
