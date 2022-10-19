module PatronMapper
  class UserRole < Shale::Mapper
    attribute :status, Shale::Type::String
    attribute :scope, Shale::Type::String
    attribute :role_type, Shale::Type::String
  end

  class UserRoles < Shale::Mapper
    attribute :user_role, UserRole
  end
end
