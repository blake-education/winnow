class User < ActiveRecord::Base
  include Winnow::Model

  scope :name_like, lambda { |str| where("name like ?", "%#{str}%") }

  def self.email_from(domain)
    where("email like '%@?", domain)
  end
end
