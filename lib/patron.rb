require "forwardable"
class Patron
  INST_ROLE_MAP = YAML.load_file("./config/umich_inst_roles_map.yaml")

  def self.base_inst_role(data)
    INST_ROLE_MAP.filter_map do |inst_role|
      inst_role if data["umichinstroles"].any? { |x| x == inst_role["key"] }
    end.first
  end

  def self.for(data)
    case base_inst_role(data)&.dig("role")
    when "student"
      Student.new(data: data)
    when "staff"
      StaffPerson.new(data: data)
    else
      Employee.new(data: data)
    end
  end

  extend Forwardable
  def_delegators :@name, :first_name, :last_name, :middle_name, :middle_name?

  def initialize(data:, name: Name.new(data))
    @data = data
    @name = name
  end

  def uniqname
    @data["uid"]&.first
  end

  def primary_id
    @data["uid"]&.first
  end

  def record_type
    "PUBLIC"
  end

  def external_id
    "SIS"
  end

  def campus_code
    raise NotImplementedError
  end

  def user_group
    raise NotImplementedError
  end

  def status
    "ACTIVE"
  end

  def job_description
    raise NotImplementedError
  end

  def stastic_category
    raise NotImplementedError
  end

  def email_address
    @data["mail"]&.first
  end

  def email_type
    raise NotImplementedError
  end

  def umich_address_type
    raise NotImplementedError
  end

  def umich_address
    raw_address = [@data["umichpostaladdressdata"]&.first, @data["umichhomepostaladdressdata"]&.first].compact.first
    return if raw_address.nil?
    address = ldap_field(raw_address)
    address.type = umich_address_type
    Address.new(address)
  end

  def permanent_address
    raw_address = [@data["umichpermanentpostaladdressdata"]&.first, @data["umichhomepostaladdressdata"]&.first].compact.first
    return if raw_address.nil?
    address = ldap_field(raw_address)
    address.type = "home"
    Address.new(address)
  end

  def addresses
    [umich_address, permanent_address].compact.map.with_index do |address, index|
      if index == 0
        raw = address.raw
        raw.preferred = true
        Address.new(raw)
      else
        address
      end
    end
  end

  def phone_number
    # to be implemented
  end

  # private?
  def role
    base_inst_role["role"]
  end

  def base_inst_role
    self.class.base_inst_role(@data)
  end

  def ldap_fields(array)
    array.map do |row|
      ldap_field(row)
    end
  end

  def ldap_field(row)
    OpenStruct.new(row.split(":").map do |element|
      element.gsub(/["{}]/, "").split("=")
    end.to_h)
  end

  class Address
    attr_reader :raw
    def initialize(address)
      @raw = address
    end

    def line1
      @raw.addr1 || "(no address)"
    end

    def line2
    end

    def city
    end

    def state_province
    end

    def postal_code
    end

    def country
    end

    def type
      @raw.type
    end

    def preferred
      @raw.preferred || false
    end
  end
end
