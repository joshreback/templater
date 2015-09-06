require 'test_helper'

class SqlTemplateTest < ActiveSupport::TestCase
  test "resolver returns a template with the saved body" do
    resolver = SqlTemplate::Resolver.instance

    details = { formats: [:html], locale: [:en], handlers: [:erb] }

    # 1) Assert our resolver cannot finda ny template as the database is empty
    assert resolver.find_all("index", "posts", false, details).empty?

    # 2) Create a template in the database
    SqlTemplate.create!(
      body: "<%= 'Hi from SqlTemplate!' %>",
      path: "posts/index",
      format: "html",
      locale: "en",
      handler: "erb",
      partial: false)

    # 3) Assert that a template can now be found
    template = resolver.find_all("index", "posts", false, details).first
    assert_kind_of ActionView::Template, template

    # 4) Assert specific information about the found template
    # NOTE: the find_all() method in the resolver should return an ActionView::Template instance
    # This template instance is initialized as: ActionView::Template.new(source, identifier, handler, details)
    assert_equal "<%= 'Hi from SqlTemplate!' %>", template.source
    assert_kind_of ActionView::Template::Handlers::ERB, template.handler
    assert_equal [:html], template.formats
    assert_equal "posts/index", template.virtual_path
    assert_match %r[SqlTemplate - \d+ - "posts/index"], template.identifier
  end

  test "sql_template expires the cache on update" do
    cache_key = Object.new
    resolver = SqlTemplate::Resolver.instance
    details = { formats: [:html], locale: [:en], handlers: [:erb] }

    t = resolver.find_all("index", "users", false, details, cache_key).first
    assert_match %r{Listing Users}, t.source

    sql_template = sql_templates(:users_index)
    sql_template.update_attributes(body: "New body for template")

    t = resolver.find_all("index", "users", false, details, cache_key).first
    assert_equal "New body for template", t.source
  end
end
