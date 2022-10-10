require_relative "./name"
class Patron
  def initialize(data:, name: Name.new(data))
    @data = data
    @inst_role_map = YAML.load_file("./config/umich_inst_roles_map.yaml")
    @name = name
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

  def campus_code
    # can someone have multiple campus codes? can there be faculty at Flint and student in Ann Arbor?
    @data["umichinstroles"].filter_map { |x| @inst_role_map[x]["campus"] unless @inst_role_map[x].nil? }.first
  end

  def job_description
    @data["umichhr"].map do |x|
      h = x.split(":").map do |y|
        y.gsub(/[{}]/, "").split("=")
      end.to_h
      "#{h["deptDescription"]} (#{h["deptId"]})"
    end.first
  end
end
