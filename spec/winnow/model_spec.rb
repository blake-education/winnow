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
      ActiveRecord::Relation.any_instance.should_receive(:where).with(name: "Don Gately")
      User.search(name: "Don Gately")
    end

    it "should set up contains conditions on any fields defined as contains searchable" do
      User.searchable(:name_contains)
      ActiveRecord::Relation.any_instance.should_receive(:where).with("users.name like ?", "%ate%")
      User.search(name_contains: "ate")
    end

    it "should set up starts_with conditions on any fields defined as starts_with searchable" do
      User.searchable(:name_starts_with)
      ActiveRecord::Relation.any_instance.should_receive(:where).with("users.name like ?", "Pete%")
      User.search(name_starts_with: "Pete")
    end

    it "should call all searchables if multiple params passed in" do
      User.searchable(:email_from, :email)
      User.should_receive(:email_from).with("Incand").and_return(User) # fake return otherwise our expectations get confused
      User.should_receive(:where).with(email: "hal@eta.edu").and_call_original
      User.search(email_from: "Incand", email: "hal@eta.edu")
    end

    context 'with boolean columns' do
      before { User.searchable(:awesome) }

      it "should convert 'true' to true" do
        ActiveRecord::Relation.any_instance.should_receive(:where).with(awesome: true).and_call_original
        User.search(awesome: 'true')
      end

      it "should convert 'false' to false" do
        ActiveRecord::Relation.any_instance.should_receive(:where).with(awesome: false).and_call_original
        User.search(awesome: 'false')
      end

      it "should handle true as you'd expect" do
        ActiveRecord::Relation.any_instance.should_receive(:where).with(awesome: true).and_call_original
        User.search(awesome: true)
      end

      it "should handle false as you'd expect" do
        ActiveRecord::Relation.any_instance.should_receive(:where).with(awesome: false).and_call_original
        User.search(awesome: false)
      end

      it "should ignore falsy values (except false)" do
        User.should_not_receive(:where)
        ActiveRecord::Relation.any_instance.should_not_receive(:where)
        User.search(awesome: nil)
        User.search(awesome: '')
      end

      it "should convert truthy to true" do
        ActiveRecord::Relation.any_instance.should_receive(:where).with(awesome: true).and_call_original
        User.search(awesome: 'whatever')
      end
    end

    it "should include any previous scopes in the query" do
      User.searchable(:email)
      scope = User.where(name: "Hal").search(email: "hal@eta.edu").scope
      # TOFIX is there a better way to test this?
      scope.to_sql.should include %Q{WHERE "users"."name" = 'Hal' AND "users"."email" = 'hal@eta.edu'}
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
      ActiveRecord::Relation.any_instance.should_receive(:where).with(email: "mario@eta.edu")
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
