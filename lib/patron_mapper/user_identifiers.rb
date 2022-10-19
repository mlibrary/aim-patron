module PatronMapper
  class UserIdentifier < Shale::Mapper
    attribute :id_type, Shale::Type::String
    attribute :value, Shale::Type::String
    attribute :status, Shale::Type::String
  end

  class UserIdentifiers < Shale::Mapper
    attribute :user_identifier, UserIdentifier, collection: true
  end
end
