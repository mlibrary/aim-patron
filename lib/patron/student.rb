class Patron
  class Student < Patron
    def campus_code
      base_inst_role["campus"]
    end

    def email_type
      "school"
    end

    def umich_address_type
      "school"
    end
  end
end
