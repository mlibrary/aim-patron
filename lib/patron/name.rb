class Patron
  class Name
    def initialize(data)
      @given_name = data["givenname"]&.first
      @umich_display_sn = data["umichdisplaysn"]&.first
      @umich_display_middle = data["umichdisplaymiddle"]&.first
      @display_name = data["displayname"]&.first
    end

    def first_name
      @given_name || display_name_array.first
    end

    def middle_name
      if @umich_display_middle
        @umich_display_middle
      elsif display_name_array.length > 2
        display_name_array[1]
      end
    end

    def last_name
      @umich_display_sn || display_name_array.last
    end

    def middle_name?
      !!middle_name
    end

    def display_name_array
      @display_name&.split(" ") || []
    end
  end
end
