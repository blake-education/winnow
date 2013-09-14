require "spec_helper"

describe Winnow::Model do
  # N.B. See spec/dummy/app/model.rb for info

  describe ".searchable" do
    it "should accept field names" do
      User.searchable(:name)
      User.searchables.should eq [:name]
    end

    it "should accept scopes" do
      User.searchable(:name_like)
      User.searchables.should eq [:name_like]
    end

    it "should accept class methods" do
      User.searchable(:email_from)
      User.searchables.should eq [:email_from]
    end

    it "should accept arrays of names" do
      User.searchable(:name, :email_from)
      User.searchables.should eq [:name, :email_from]
    end

    it "should raise an error if an unknown name is passed in" do
      expect { User.searchable(:some_other_method) }.to raise_error(RuntimeError, "Unknown searchable: :some_other_method")
    end

    it "should include all unknown names in error" do
      expect { User.searchable(:name, :some_other_method, :another_method) }.to raise_error(RuntimeError, "Unknown searchable: :some_other_method, :another_method")
    end
  end
end
