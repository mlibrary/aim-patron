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
    # can someone have multiple campus codes? can there be faculty at Flint and student in Ann Arbor?
    base_inst_role["campus"]
  end

  def job_description
    @data["umichhr"].map do |x|
      h = x.split(":").map do |y|
        y.gsub(/[{}]/, "").split("=")
      end.to_h
      "#{h["deptDescription"]} (#{h["deptId"]})"
    end.first
  end

  # private?
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
