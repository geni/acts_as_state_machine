Gem::Specification.new do |spec|
  spec.name = 'acts_as_state_machine'
  spec.version = '8.0.0'
  spec.date = '2025-07-04'

  spec.summary = "Allows ActiveRecord models to define states and transition actions between them"
  spec.description = "This act gives an Active Record model the ability to act as a finite state machine (FSM)."

  spec.authors = ['RailsJedi', 'Scott Barron', 'Scott Steadman']
  spec.email = ['railsjedi@gmail.com', 'scott.steadman@geni.com']
  spec.homepage = 'http://github.com/geni/acts_as_state_machine'

  spec.add_dependency 'activerecord', '~> 8.0.0'

  spec.files = ["CHANGELOG",
              "MIT-LICENSE",
              "README",
              "Rakefile",
              "TODO",
              "acts_as_state_machine.gemspec",
              "init.rb",
              "lib/acts_as_state_machine.rb",
              "rails/init.rb"]

  spec.test_files = ["test/fixtures",
                    "test/fixtures/conversations.yml",
                    "test/test_acts_as_state_machine.rb"]
end