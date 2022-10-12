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

  # private?
  def role
    base_inst_role["role"]
  end

  def base_inst_role
    self.class.base_inst_role(@data)
  end

  def ldap_fields(array)
    array.map do |row|
      OpenStruct.new(row.split(":").map do |element|
        element.gsub(/["{}]/, "").split("=")
      end.to_h)
    end
  end
end
