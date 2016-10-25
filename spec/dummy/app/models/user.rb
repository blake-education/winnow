class User < ActiveRecord::Base
  include Winnow::Model

  scope :name_ends_with, lambda { |str| where("name like ?", "%#{str}") }

  def self.email_from(domain)
    where("email like '%@?", domain)
  end
end
