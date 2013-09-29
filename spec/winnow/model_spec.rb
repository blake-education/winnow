require "spec_helper"

describe Winnow::Model do
  # N.B. See spec/dummy/app/model.rb for info

  describe ".searchable" do
    it "should accept field names" do
      User.searchable(:name)
      User.searchables.should eq [:name]
    end

    it "should accept field names contains" do
      User.searchable(:name_contains)
      User.searchables.should eq [:name_contains]
    end

    it "should accept scopes" do
      User.searchable(:name_starts_with)
      User.searchables.should eq [:name_starts_with]
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
      User.searchable(:name_starts_with)
      User.should_receive(:name_starts_with).with("Joelle").and_call_original
      User.search(name_starts_with: "Joelle")
    end

    it "should call any scopes defined as searchable" do
      User.searchable(:email_from)
      User.should_receive(:email_from).with("gmail.com").and_call_original
      User.search(email_from: "gmail.com")
    end

    it "should set up equality conditions on any fields defined as searchable" do
      User.searchable(:name)
      User.should_receive(:where).with(name: "Don Gately").and_call_original
      User.search(name: "Don Gately")
    end

    it "should set up contains conditions on any fields defined as contains searchable" do
      User.searchable(:name_contains)
      User.should_receive(:where).with("users.name like ?", "%ate%").and_call_original
      User.search(name_contains: "ate")
    end

    it "should call all searchables if multiple params passed in" do
      User.searchable(:email_from, :email)
      User.should_receive(:email_from).with("Incand").and_return(User) # fake return otherwise our expectations get confused
      User.should_receive(:where).with(email: "hal@eta.edu").and_call_original
      User.search(email_from: "Incand", email: "hal@eta.edu")
    end

    it "should ignore any non-searchable parameters" do
      User.searchable(:name)
      User.should_not_receive(:where)
      User.search(email: "hal@eta.edu")
    end

    it "should ignore any empty arrays" do
      User.should_not_receive(:where)
      User.search(nil)
    end

    it "should ignore any blank parameters" do
      User.searchable(:name, :email)
      User.should_receive(:where).with(email: "mario@eta.edu")
      User.search(name: "", email: "mario@eta.edu")
    end

    it "should return a Winnow::FormObject" do
      obj = User.search(nil)
      obj.class.should eq Winnow::FormObject
      obj.klass.should eq User
      obj.klass.should eq User
      obj.params.should == {}
    end
  end
end
