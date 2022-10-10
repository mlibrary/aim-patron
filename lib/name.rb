class Name
  def initialize(data)
    @givenName = data["givenname"]&.first
    @umichdisplaysn = data["umichdisplaysn"] 
    @umichDisplayMiddle = data["umichdisplaymiddle"] 
  end

  def first_name
  end
  def middle_name
  end
  def last_name
  end
end
