class Patron
  class FlintStudent < Patron::RegionalStudent
    def campus_code
      "UMFL"
    end

    def ldap_campus
      "flnt"
    end
  end
end
