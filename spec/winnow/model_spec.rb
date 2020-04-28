require "spec_helper"

describe Winnow::Model do
  # N.B. See spec/dummy/app/model.rb for info

  describe ".searchable" do
    it "should accept field names" do
      User.searchable(:name)
      expect(User.searchables).to eq [:name]
    end

    it "should accept field names contains" do
      User.searchable(:name_contains)
      expect(User.searchables).to eq [:name_contains]
    end

    it "should accept scopes" do
      User.searchable(:name_starts_with)
      expect(User.searchables).to eq [:name_starts_with]
    end

    it "should accept class methods" do
      User.searchable(:email_from)
      expect(User.searchables).to eq [:email_from]
    end

    it "should accept arrays of names" do
      User.searchable(:name, :email_from)
      expect(User.searchables).to eq [:name, :email_from]
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
      User.searchable(:name_ends_with)
      expect(User).to receive(:name_ends_with).with("Joelle").and_call_original
      User.search(name_ends_with: "Joelle")
    end

    it "should call any scopes defined as searchable" do
      User.searchable(:email_from)
      expect(User).to receive(:email_from).with("gmail.com").and_call_original
      User.search(email_from: "gmail.com")
    end

    it "should set up equality conditions on any fields defined as searchable" do
      User.searchable(:name)
      expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(name: "Don Gately")
      User.search(name: "Don Gately")
    end

    it "should set up contains conditions on any fields defined as contains searchable" do
      User.searchable(:name_contains)
      expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with("users.name like ?", "%ate%")
      User.search(name_contains: "ate")
    end

    it "should set up starts_with conditions on any fields defined as starts_with searchable" do
      User.searchable(:name_starts_with)
      expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with("users.name like ?", "Pete%")
      User.search(name_starts_with: "Pete")
    end

    it "should call all searchables if multiple params passed in" do
      User.searchable(:email_from, :email)
      expect(User).to receive(:email_from).with("Incand").and_return(User) # fake return otherwise our expectations get confused
      expect(User).to receive(:where).with(email: "hal@eta.edu").and_call_original
      User.search(email_from: "Incand", email: "hal@eta.edu")
    end

    context 'with boolean columns' do
      before { User.searchable(:awesome) }

      it "should convert 'true' to true" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(awesome: true).and_call_original
        User.search(awesome: 'true')
      end

      it "should convert 'false' to false" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(awesome: false).and_call_original
        User.search(awesome: 'false')
      end

      it "should handle true as you'd expect" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(awesome: true).and_call_original
        User.search(awesome: true)
      end

      it "should handle false as you'd expect" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(awesome: false).and_call_original
        User.search(awesome: false)
      end

      it "should ignore falsy values (except false)" do
        expect(User).to_not receive(:where)
        expect_any_instance_of(ActiveRecord::Relation).to_not receive(:where)
        User.search(awesome: nil)
        User.search(awesome: '')
      end

      it "should convert truthy to true" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(awesome: true).and_call_original
        User.search(awesome: 'whatever')
      end
    end

    it "should include any previous scopes in the query" do
      User.searchable(:email)
      scope = User.where(name: "Hal").search(email: "hal@eta.edu").scope
      # TOFIX is there a better way to test this?
      expect(scope.to_sql).to include %Q{WHERE "users"."name" = 'Hal' AND "users"."email" = 'hal@eta.edu'}
    end

    it "should ignore any non-searchable parameters" do
      User.searchable(:name)
      expect(User).to_not receive(:where)
      User.search(email: "hal@eta.edu")
    end

    it "should ignore any empty arrays" do
      expect(User).to_not receive(:where)
      User.search(nil)
    end

    it "should ignore any blank parameters" do
      User.searchable(:name, :email)
      expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(email: "mario@eta.edu")
      User.search(name: "", email: "mario@eta.edu")
    end

    it "should return a Winnow::FormObject" do
      obj = User.search(nil)
      expect(obj.class).to eq Winnow::FormObject
      expect(obj.klass).to eq User
      expect(obj.klass).to eq User
      expect(obj.params).to eq({})
    end

    let(:fts_scope) do
      "(match(users.name) against(? in boolean mode) and (users.name like ?))"
    end

    context "mysql full-text search" do
      before do
        allow(User.connection).to receive(:adapter_name) { "Mysql2" }
        User.searchable(:name_contains)
      end

      it "should use full-text search when index is available" do
        allow(User.connection).to receive(:indexes) do
          [Struct.new(:columns, :type).new(["name"], :fulltext)]
        end

        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(fts_scope, "", "%test%")
        User.search(name_contains: "test")
      end

      it "should strip out boolean search operators from search term" do
        allow(User.connection).to receive(:indexes) do
          [Struct.new(:columns, :type).new(["name"], :fulltext)]
        end

        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(fts_scope, "+test*", "%hello@test.com%")
        User.search(name_contains: "hello@test.com")
      end

      it "should default to wild-card LIKE searches when index is not present" do
        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with("users.name like ?", "%test%")
        User.search(name_contains: "test")
      end
    end

    context "fallback to full-text index" do
      before do
        allow(User.connection).to receive(:adapter_name) { "Mysql2" }
        User.searchable(:name_starts_with)
      end

      it "should use a full-text index if available to perform starts_with searches." do
        allow(User.connection).to receive(:indexes) do
          [Struct.new(:columns, :type, :using).new(["name"], :fulltext)]
        end

        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(fts_scope, "+test*", "test%")
        User.search(name_starts_with: "test")
      end

      it "should use a full-text index if available to perform starts_with searches and should use '+' in the token string" do
        allow(User.connection).to receive(:indexes) do
          [Struct.new(:columns, :type, :using).new(["name"], :fulltext)]
        end

        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with(fts_scope, "+hello* +test*", "hello@test.com%")
        User.search(name_starts_with: "hello@test.com")
      end

      it "should use btree indexes for starts_with searches." do
        allow(User.connection).to receive(:indexes) do
          [Struct.new(:columns, :type, :using).new(["name"], nil, :btree)]
        end

        expect_any_instance_of(ActiveRecord::Relation).to receive(:where).with("users.name like ?", "test%")
        User.search(name_starts_with: "test")
      end
    end
  end
end
