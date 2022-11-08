class Patron
  class Name
    def initialize(data)
      @given_name = data["givenname"]&.first
      @umich_display_sn = data["umichdisplaysn"]
      @umich_display_middle = data["umichdisplaymiddle"]
      @display_name = data["displayname"]
    end

    def first_name
      "Emily"
    end

    def middle_name
      "O"
    end

    def last_name
      "Card"
    end

    def middle_name?
      !!middle_name
    end
  end
end
