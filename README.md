[![Build Status](https://travis-ci.org/blake-education/winnow.png?branch=develop)](https://travis-ci.org/blake-education/winnow)

# Winnow

An AREL based search solution for Rails.

=

## Usage

### Gemfile

Add to Gemfile

```
gem 'winnow',            git: 'git@github.com:blake-education/winnow.git'
```

### Model

Define searchable names.

These are column names suffixed with a predicate. See [Predicates](#predicates)
for a [non-comprehensive] list

```ruby
class SomeModel < ActiveRecord::Base
  searchable :name_contains
end
```

### Controller

```ruby
def index
  SomeModel.search(params[:search])
end
```

### View

```ruby

= form_for @search, url: some_models_path, html: { method: :get } do |f|
  %label{ for: :name_contains } Name
  = f.text_field :name_contains, size: 20

```

### Predicates
See https://github.com/rails/rails/blob/master/activerecord/lib/arel/predications.rb

=

This project rocks and uses MIT-LICENSE.
