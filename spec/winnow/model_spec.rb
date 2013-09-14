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

  describe ".search" do
    it "should call any class methods defined as searchable" do
      User.searchable(:name_like)
      User.should_receive(:name_like).with("Joelle")
      User.search(name_like: "Joelle")
    end

    it "should call any scopes defined as searchable" do
      User.searchable(:email_from)
      User.should_receive(:email_from).with("gmail.com")
      User.search(email_from: "gmail.com")
    end

    it "should set up equality conditions on any fields defined as searchable" do
      User.searchable(:name)
      User.should_receive(:where).with(name: "Don Gately")
      User.search(name: "Don Gately")
    end

    it "should call all searchables if multiple params passed in" do
      User.searchable(:name_like, :email)
      User.should_receive(:where).with(email: "hal@eta.edu")
      User.should_receive(:name_like).with("Incand")
      User.search(name_like: "Incand", email: "hal@eta.edu")
    end

    it "should ignore any non-searchable parameters" do
      User.searchable(:name)
      User.should_not_receive(:where)
      User.search(email: "hal@eta.edu")
    end
  end
end
