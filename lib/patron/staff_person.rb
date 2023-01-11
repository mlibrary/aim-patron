class Patron
  class StaffPerson < Patron::Employee
    GEO_JOBCODES = [
      "205000", # GRAD STU INSTR
      "205400", # GRAD STU RES ASST
      "205800" # GRAD STU STAFF ASST
    ]

    def user_group
      geo? ? "01" : "02"
    end

    def statistic_category
      geo? ? "GE" : "ST"
    end

    def hr_criteria(hr_item)
      hr_item.jobCategory == "Staff" && hr_item.regTemp == "R"
    end

    def geo?
      GEO_JOBCODES.include?(hr_data.jobcode)
    end
  end
end
