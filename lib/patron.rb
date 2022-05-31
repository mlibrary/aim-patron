class Patron
  def initialize(data)
    @data = data
  end

  def uniqname
    @data["uid"]&.first
  end

  def primary_id
    @data["uid"]&.first
  end

  def last_name
    @data["umichdisplaysn"]&.first
  end

  def first_name
    @data["givenname"]&.first
  end
  
  def record_type
    "PUBLIC"
  end

  def external_id
    "SIS"
  end
end
