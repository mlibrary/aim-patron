class Patron
  class Faculty < Patron::Employee
    JOBCODE_TO_STATISTIC_CATEGORY = {
      "110370" => "AF", # ADJUNCT CLINICAL ASSOCIATE
      "128830" => "AF", # ADJUNCT FACULTY ASSOCIATE
      "128890" => "AF", # ADJUNCT ASST RES SCI
      "128980" => "AF", # ADJUNCT ASSOC RES SCI
      "128990" => "AF", # ADJUNCT RES SCIENTIST
      "129030" => "AF", # ADJUNCT RES INVESTIGATOR
      "129050" => "AF", # ADJUNCT CURATOR
      "129060" => "AF", # ADJUNCT ASSOC CURATOR
      "129070" => "AF", # ADJUNCT ASST CURATOR
      "201030" => "AF", # ADJUNCT PROFESSOR
      "201040" => "AF", # ADJUNCT CLINICAL PROFESSOR
      "201530" => "AF", # ADJUNCT ASSOC PROFESSOR
      "201540" => "AF", # ADJUNCT CLIN ASSOC PROF
      "202030" => "AF", # ADJUNCT ASST PROFESSOR
      "202040" => "AF", # ADJUNCT CLIN ASST PROFESSOR
      "202530" => "AF", # ADJUNCT INSTRUCTOR
      "202540" => "AF", # ADJUNCT CLINICAL INSTRUCTOR
      "203030" => "AF", # ADJUNCT LECTURER
      "203040" => "AF", # ADJUNCT CLINICAL LECTURER
      "103040" => "EM", # DEAN EMERITUS/A
      "129510" => "EM", # SR RES SCIENTIST EMERITUS
      "201070" => "EM", # PROFESSOR EMERITUS/A
      "201110" => "EM", # ASSOC PROF EMERITUS/A
      "201120" => "EM" # ASST PROF EMERITUS/A
    }
    def role
      "faculty"
    end

    def user_group
      "01"
    end

    def statistic_category
      JOBCODE_TO_STATISTIC_CATEGORY[hr_data.jobcode] || "FA"
    end

    def hr_criteria(hr_item)
      hr_item.jobCategory == "Faculty"
    end

    def exclude_reason
      "no_faculty_job_category" unless includable?
    end
  end
end
