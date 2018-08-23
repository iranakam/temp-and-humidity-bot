class User < ActiveRecord::Base
  validates :line_user_id, presence: true, uniqueness: true
end
