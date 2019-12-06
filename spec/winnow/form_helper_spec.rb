require "spec_helper"

describe "Form Helpers" do
  let(:controller){ ActionView::TestCase::TestController.new }
  let(:helper){ controller.view_context }

  it  "should generate a form" do
    User.searchable(:name)
    expect(helper.form_for(User.search(nil), url: "/"){}).to match /<form .*id="new_search".*\/>/
  end
end
