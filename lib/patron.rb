require "forwardable"
require_relative "./patron/employee"
require_relative "./patron/staff_person"
require_relative "./patron/temporary_staff_person"
require_relative "./patron/faculty"
require_relative "./patron/sponsored_affiliate"
require_relative "./patron/retiree"
require_relative "./patron/student"
require_relative "./patron/name"

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
    when "faculty"
      Faculty.new(data: data)
    when "staff"
      StaffPerson.new(data: data)
    when "temporary_staff"
      TemporaryStaffPerson.new(data: data)
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

  def includable?
    raise NotImplementedError
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
    "555-555-5555"
  end

  def phone_number?
    !!phone_number
  end

  def inst_id
    OpenStruct.new(id_type: "05", value: "#{uniqname}@umich.edu", status: "ACTIVE")
  end

  def umid
    OpenStruct.new(id_type: "02", value: @data["entityid"].first, status: "ACTIVE")
  end

  def to_h
    hash = {
      "record_type" => record_type,
      "external_id" => external_id,
      "primary_id" => primary_id,
      "first_name" => first_name,
      "middle_name" => middle_name,
      "last_name" => last_name,
      "campus_code" => campus_code,
      "user_group" => user_group,
      "status" => status,
      # "status_date" => status_date, not a thing in alma????
      "expiry_date" => expiry_date,
      "purge_date" => purge_date,
      "job_description" => job_description,
      "user_statistics" => {
        "user_statistic" => {
          "statistic_category" => statistic_category
        }
      },
      "user_roles" => {
        "user_role" => {
          "status" => "ACTIVE",
          "scope" => "01UMICH_INST",
          "role_type" => "200"
        }
      },
      "contact_info" => {
        "emails" => {
          "email" =>
           {
             "preferred" => true,
             "email_address" => email_address,
             "email_types" => {"email_type" => email_type}
           }
        }
      },
      "user_identifiers" => {
        "user_identifier" => [
          {
            "id_type" => umid.id_type,
            "value" => umid.value,
            "status" => umid.status
          },
          {
            "id_type" => inst_id.id_type,
            "value" => inst_id.value,
            "status" => inst_id.status
          }
        ]
      }
    }
    # hash[:middle_name] = middle_name if middle_name?
    if phone_number?
      hash["contact_info"]["phones"] = {"phone" =>
        {
          "preferred" => true,
          "phone_number" => phone_number,
          "phone_types" => {"phone_type" => "home"}
        }}
    end
    if addresses?
      hash["contact_info"]["addresses"] = {"address" =>
        addresses.map do |address|
          address.to_h
        end}
    end
    hash
  end

  def to_json
    to_h.to_json
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
      hash = ["preferred", "line1", "line2", "city", "country", "state_province", "postal_code"].map do |x|
        [x, public_send(x)]
      end.compact.to_h
      hash["address_types"] = {"address_type" => type}
      hash
    end
  end
end
