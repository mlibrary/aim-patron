module PatronMapper
  class UserStatistic < Shale::Mapper
    attribute :statistic_category, Shale::Type::String
  end

  class UserStatistics < Shale::Mapper
    attribute :user_statistic, PatronMapper::UserStatistic
  end
end
