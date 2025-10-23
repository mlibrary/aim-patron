class Patron
  class Student < Patron
    [
      "campus_code",
      "exclude_reason",
      "includable?",
      "job_description",
      "statistic_category",
      "user_group"
    ].each do |method|
      define_method method do
        # all of these are NotImplementedError
        super
      end
    end

    def email_type
      "school"
    end

    def umich_address_type
      "school"
    end
  end
end
