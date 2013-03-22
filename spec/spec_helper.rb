require 'puppet'
require 'rspec/mocks'
require 'mocha/api'

RSpec.configure do |c|
  c.mock_with :mocha
end
