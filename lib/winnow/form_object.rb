module Winnow
  class FormObject < Struct.new(:klass, :scope, :params)
    def self.model_name
      ActiveModel::Name.new(self).tap do |name|
        name.instance_variable_set("@param_key", "search")
      end
    end

    # c/o meta_search
    RELATION_METHODS = [
      # Query construction
      :joins, :includes, :select, :order, :where, :having, :group,
      # Results, debug, array methods
      :to_a, :all, :length, :size, :to_sql, :debug_sql, :paginate, :page,
      :find_each, :first, :last, :each, :arel, :in_groups_of, :group_by,
      # Calculations
      :count, :average, :minimum, :maximum, :sum
    ]
    delegate *RELATION_METHODS + [:to => :scope]

    def initialize(*args)
      super(*args)

      Winnow.searchables(klass).each do |name|
        (class << self; self; end).class_eval do
          define_method(name) { params[name] }
        end
      end
    end

    def to_key
      nil
    end
  end
end
