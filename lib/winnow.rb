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
end
