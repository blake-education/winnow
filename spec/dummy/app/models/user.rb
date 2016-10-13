class User < ActiveRecord::Base
  include Winnow::Model

  scope :name_starts_with, lambda { |str| where("users.name like ?", "#{str}%") }

  def self.email_from(domain)
    where("email like '%@?", domain)
  end
end
