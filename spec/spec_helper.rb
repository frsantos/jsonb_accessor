# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "jsonb_accessor"
require "pry"
require "pry-nav"
require "pry-doc"
require "awesome_print"
require "database_cleaner-active_record"
require "yaml"
require "active_support/testing/time_helpers"

dbconfig = YAML.safe_load(ERB.new(File.read(File.join("db", "config.yml"))).result, aliases: true)
ActiveRecord::Base.establish_connection(dbconfig["test"])
ActiveRecord::Base.logger = Logger.new($stdout, level: :warn)

class StaticProduct < ActiveRecord::Base
  self.table_name = "products"
  belongs_to :product_category
end

class Product < StaticProduct
  jsonb_accessor :options, title: :string, rank: :integer, made_at: :datetime
end

class ProductCategory < ActiveRecord::Base
  jsonb_accessor :options, title: :string
  has_many :products
end

RSpec::Matchers.define :attr_accessorize do |attribute_name|
  match do |actual|
    actual.respond_to?(attribute_name) && actual.respond_to?("#{attribute_name}=")
  end
end

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.around :example, :tz do |example|
    Time.use_zone(example.metadata[:tz]) { example.run }
  end

  config.around :example, :ar_default_tz do |example|
    active_record_base = if ActiveRecord.respond_to? :default_timezone
                           ActiveRecord
                         else
                           ActiveRecord::Base
                         end
    old_default = active_record_base.default_timezone
    active_record_base.default_timezone = example.metadata[:ar_default_tz]
    example.run
    active_record_base.default_timezone = old_default
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 0
  config.order = :random
  Kernel.srand config.seed

  config.before do
    DatabaseCleaner.clean_with(:truncation)
    # treat warnings as error for example when Rails warns that some method is being overridden.
    expect_any_instance_of(Logger).to_not receive(:warn)
  end
end
