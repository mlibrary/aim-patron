class Patron
  def initialize(data)
    @data = data
  end

  def uniqname
    @data["uid"]&.first
  end
end
