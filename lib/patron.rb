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

  def expiry_date
  end

  def purge_date
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

  def statistic_category
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

  def addresses?
    !addresses.empty?
  end

  def email_address
    @data["mail"]&.first
  end

  def email_type
    raise NotImplementedError
  end

  def phone_number
    # to be implemented
  end

  def phone_number?
    !!phone_number
  end

  def inst_id
    OpenStruct.new(id_type: "05", value: "#{uniqname}@umich.edu", status: "ACTIVE")
  end

  def umid
    OpenStruct.new(id_type: "02", value: @data["uidnumber"].first, status: "ACTIVE")
  end

  def to_h
    hash = {
      record_type: {
        value: record_type
      },
      external_id: external_id,
      primary_id: primary_id,
      # first_name: first_name,
      # middle_name: middle_name,
      # last_name: last_name,
      campus_code: {
        value: campus_code
      },
      user_group: {
        value: user_group
      },
      status: {
        value: status
      },
      # status_date: status_date, not a thing in alma????
      expiry_date: expiry_date,
      purge_date: purge_date,
      job_description: job_description,
      user_statistic: [
        {
          statistic_category: {
            value: statistic_category
          }
        }
      ],
      user_role: [
        {
          status: {value: "ACTIVE"},
          scope: {value: "01UMICH_INST"},
          role_type: {value: "200"}
        }
      ],
      contact_info: {
        address: [],
        email: [
          {
            preferred: true,
            email_address: email_address,
            email_type: {
              value: email_type
            }
          }
        ],
        phone: []
      },
      user_identifier: [
        {
          id_type: umid.id_type,
          value: umid.value,
          status: umid.active
        },
        {
          id_type: inst_id.id_type,
          value: inst_id.value,
          status: inst_id.active
        }
      ]
    }
    hash[:middle_name] = middle_name if middle_name?
    if phone_number?
      hash[:contact_info][:phone].push(
        {
          preferred: true,
          phone_number: phone_number,
          phone_type: [
            {value: "home"}
          ]
        }
      )
    end
    if addresses?
      hash[:contact_info][:address].push(
        addresses.map do |address|
          address.to_h
        end
      )
    end
    hash
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
      @raw&.addr1 || "(no address)"
    end

    def line2
      @raw&.addr2
    end

    def city
      @raw&.city
    end

    def state_province
      @raw&.state
    end

    def postal_code
      @raw&.postal
    end

    def country
      @raw&.nation
    end

    def type
      @raw.type
    end

    def preferred
      @raw.preferred || false
    end

    def to_h
      hash = ["preferred", "line1", "line2", "city", "state_province", "postal_code"].map do |x|
        [x.to_sym, public_send(x)] if public_send(x)
      end.compact.to_h
      hash[:country] = {value: country} if country
      hash[:address_type] = {value: type}
      hash
    end
  end
end
