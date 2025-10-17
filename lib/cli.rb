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
    puts uniqname
    # ProcessLdapOneUser.new(uniqname).ldap_output
  end
end
