require "winnow/form_object"
require "winnow/model"

module Winnow
  def self.searchables(klass)
    @searchables ||= {}
    @searchables[klass] || {}
  end

  def self.add_searchable(klass, params)
    @searchables ||= {}
    @searchables[klass] = params
  end

  def self.boolean(value)
    return false if value == 'false'
    !!value
  end

  def self.base_scope_method
    @base_scope_method ||= choose_base_scope_method
  end

  def self.choose_base_scope_method
    if rails_has_all?
      :all
    else
      :scoped
    end
  end

  def self.rails_has_all?
    defined?(ActiveRecord::VERSION::STRING) && 
      (ActiveRecord::VERSION::STRING =~ /^4/  || ActiveRecord::VERSION::STRING =~ /^5/)
  end
end
