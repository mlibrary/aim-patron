require "thor"
require_relative "process_ldap"

class CLI < Thor
  def self.exit_on_failure?
    true
  end

  desc "hello", "Prints a greeting"
  def hello
    puts "hello world"
  end

  desc "ldap UNIQNAME", "returns the ldap info for a user"
  def ldap(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).ldap_output
  end

  desc "one UNIQNAME", "returns the xml for the uniqname"
  def one(uniqname)
    ProcessLdapOneUser.new(uniqname: uniqname).process
  end

end
