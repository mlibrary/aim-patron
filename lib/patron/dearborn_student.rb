class Patron
  class DearbornStudent < Patron::RegionalStudent
    def campus_code
      "UMDB"
    end

    def ldap_campus
      "dbrn"
    end
  end
end
