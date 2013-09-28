require "spec_helper"

describe Winnow::FormObject do
  describe ".model_name" do
  end

  describe "creation" do
    it "should handle models with no calls to searchable" do
      # just ignore them, basically
      expect { Winnow::FormObject.new(User, {}) }.not_to raise_error
    end

    it "should set up methods for any params passed in" do
      # form_for will call these methods, so need to define them
      User.searchable(:name_starts_with, :email_from)
      obj = Winnow::FormObject.new(User, User, name_starts_with: "A", email_from: "B")
      obj.name_starts_with.should eq "A"
      obj.email_from.should eq "B"
    end

    it "should not set up methods for any non-searchable params" do
      # form_for will call these methods, so need to define them
      User.searchable(:name_starts_with)
      obj = Winnow::FormObject.new(User, User, name_starts_with: "A", email_from: "B")
      obj.name_starts_with.should eq "A"
      obj.respond_to?(:email_from).should be_false
    end
  end

  describe "#to_key" do
    it "should return nil" do
      # I don't really know why, but things fail if to_key is not defined
      Winnow::FormObject.new(User, User, {}).to_key.should be_nil
    end
  end
end
