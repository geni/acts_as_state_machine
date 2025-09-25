require 'acts_as_state_machine'

if defined?(ApplicationRecord)
  ApplicationRecord.send(:include, ScottBarron::Acts::StateMachine)
else
  ActiveRecord::Base.send(:include, ScottBarron::Acts::StateMachine)
end
