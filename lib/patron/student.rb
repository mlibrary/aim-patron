class Patron
  class Student < Patron
    def campus_code
      raise NotImplementedError
      # base_inst_role["campus"]
    end

    def email_type
      "school"
    end

    def umich_address_type
      "school"
    end
  end
end
