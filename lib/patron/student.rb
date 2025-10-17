class Patron
  class Student < Patron
    def campus_code
      raise NotImplementedError
    end

    def email_type
      "school"
    end

    def umich_address_type
      "school"
    end
  end
end
