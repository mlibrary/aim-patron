module PatronMapper
  class User < Shale::Mapper
    attribute :record_type, Shale::Type::String
    attribute :external_id, Shale::Type::String
    attribute :primary_id, Shale::Type::String
    attribute :first_name, Shale::Type::String
    attribute :middle_name, Shale::Type::String
    attribute :last_name, Shale::Type::String
    attribute :campus_code, Shale::Type::String
    attribute :user_group, Shale::Type::String
    attribute :status, Shale::Type::String
    attribute :expiry_date, Shale::Type::String
    attribute :purge_date, Shale::Type::String
    attribute :job_description, Shale::Type::String
    attribute :user_statistics, UserStatistics
    attribute :user_roles, UserRoles
    attribute :contact_info, ContactInfo
    attribute :user_identifiers, UserIdentifiers
  end
end
