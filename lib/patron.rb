require "forwardable"
require_relative "patron/employee"
require_relative "patron/staff_person"
require_relative "patron/temporary_staff_person"
require_relative "patron/faculty"
require_relative "patron/sponsored_affiliate"
require_relative "patron/retiree"
require_relative "patron/student"
require_relative "patron/ann_arbor_student"
require_relative "patron/regional_student"
require_relative "patron/flint_student"
require_relative "patron/dearborn_student"

require_relative "patron/name"

class Patron
  INST_ROLE_MAP = YAML.load_file("./config/umich_inst_roles_map.yaml")

  def self.base_inst_role(data)
    INST_ROLE_MAP.find { |inst_role| data["umichinstroles"].any? { |x| x == inst_role["key"] } }
  end

  # def self.for(data)
  # inst_role = base_inst_role(data)
  # case inst_role&.dig("role")
  # when "student"
  # case inst_role["campus"]
  # when "UMAA"
  # AnnArborStudent.new(data: data)
  # when "UMDB"
  # DearbornStudent.new(data: data)
  # when "UMFL"
  # FlintStudent.new(data: data)
  # end
  # when "faculty"
  # Faculty.new(data: data)
  # when "staff"
  # StaffPerson.new(data: data)
  # when "temporary_staff"
  # TemporaryStaffPerson.new(data: data)
  # when "sponsored_affiliate"
  # SponsoredAffiliate.new(data: data)
  # when "retiree"
  # Retiree.new(data: data)
  # end
  # end

  def self.inst_roles_for(data)
    INST_ROLE_MAP.select do |inst_role|
      data["umichinstroles"].include?(inst_role["key"])
    end
  end

  def self.valid_for(data)
    return if test_user?(data)
    inst_roles = inst_roles_for(data)
    result = inst_roles.filter_map do |inst_role|
      user = for_inst_role(inst_role: inst_role, data: data)
      user if user.includable?
    end
    result&.first
  end

  def self.exclude_reasons_for(data)
    return ["Uniqname: #{data["uid"]}\tExclude Reason: test_user"] if test_user?(data)
    inst_roles = inst_roles_for(data)
    inst_roles.map do |inst_role|
      user = for_inst_role(inst_role: inst_role, data: data)
      "Uniqname: #{user.primary_id}\tInst Role: #{inst_role["key"]}\tExclude Reason: #{user.exclude_reason}"
    end
  end

  def self.test_user?(data)
    data["uid"].first.match?(/ststv/)
  end

  def self.for_inst_role(inst_role:, data:)
    case inst_role["role"]
    when "student"
      case inst_role["campus"]
      when "UMAA"
        AnnArborStudent.new(data: data)
      when "UMDB"
        DearbornStudent.new(data: data)
      when "UMFL"
        FlintStudent.new(data: data)
      end
    when "faculty"
      Faculty.new(data: data)
    when "staff"
      StaffPerson.new(data: data)
    when "temporary_staff"
      TemporaryStaffPerson.new(data: data)
    when "sponsored_affiliate"
      SponsoredAffiliate.new(data: data)
    when "retiree"
      Retiree.new(data: data)
    end
  end

  extend Forwardable
  def_delegators :@name, :first_name, :last_name, :middle_name, :middle_name?

  def initialize(data:, name: Name.new(data), current_schedule: CurrentSchedule.new)
    @data = data
    @name = name
    @current_schedule = current_schedule
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
    @current_schedule.default_expiry_date
  end

  def purge_date
    expiry_date.next_year(2)
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
    @data["telephonenumber"]&.first || @data["umichpermanentphone"]&.first
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
      "expiry_date" => expiry_date.strftime("%D"),
      "purge_date" => purge_date.strftime("%D"),
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
    OpenStruct.new(row.split("}:").map do |element|
      array = element.gsub(/["{}]/, "").split("=")
      array[1] = nil if array.length == 1
      array
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
