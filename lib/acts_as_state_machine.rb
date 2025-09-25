module ScottBarron                   #:nodoc:
  module Acts                        #:nodoc:
    module StateMachine              #:nodoc:

      InvalidState   = Class.new(StandardError)
      NoInitialState = Class.new(StandardError)

      def self.included(base)        #:nodoc:
        base.extend ActMacro
      end

      module SupportingClasses
        # Default transition action.  Always returns true.
        NOOP = lambda { |o| true }

        class State
          attr_reader :name, :value

          def initialize(name, options)
            @name  = name.to_sym
            @value = (options[:value] || @name).to_s
            @after = Array(options[:after])
            @enter = options[:enter] || NOOP
            @exit  = options[:exit] || NOOP
          end

          def entering(record)
            record.send(:run_transition_action, @enter)
          end

          def entered(record)
            @after.each { |action| record.send(:run_transition_action, action) }
          end

          def exited(record)
            record.send(:run_transition_action, @exit)
          end
        end

        class StateTransition
          attr_reader :from, :to, :opts

          def initialize(options)
            @from  = options[:from].to_s
            @to    = options[:to].to_s
            @guard = options[:guard] || NOOP
            @opts  = options
          end

          def guard(obj)
            @guard ? obj.send(:run_transition_action, @guard) : true
          end

          def perform(record)
            return false unless guard(record)
            loopback = record.current_state.to_s == to
            states = record.class._aasm_states
            next_state = states[to]
            old_state = states[record.current_state.to_s]

            next_state.entering(record) unless loopback

            record.update_attribute(record.class._aasm_state_column, next_state.value)

            next_state.entered(record) unless loopback
            old_state.exited(record) unless loopback
            true
          end

          def ==(obj)
            @from == obj.from && @to == obj.to
          end
        end

        class Event
          attr_reader :name
          attr_reader :transitions
          attr_reader :opts

          def initialize(name, opts, transition_table, &block)
            @name = name.to_sym
            @transitions = transition_table[@name] = []
            instance_eval(&block) if block
            @opts = opts
            @opts.freeze
            @transitions.freeze
            freeze
          end

          def next_states(record)
            @transitions.select { |t| t.from == record.current_state.to_s }
          end

          def fire(record)
            next_states(record).each do |transition|
              break true if transition.perform(record)
            end
          end

          def transitions(trans_opts)
            Array(trans_opts[:from]).each do |s|
              @transitions << SupportingClasses::StateTransition.new(trans_opts.merge({:from => s.to_sym}))
            end
          end
        end
      end

      module ActMacro
        # Configuration options are
        #
        # * +column+ - specifies the column name to use for keeping the state (default: state)
        # * +initial+ - specifies an initial state for newly created objects (required)
        def acts_as_state_machine(options = {})
          class_eval do
            raise NoInitialState unless options[:initial]

            extend ClassMethods
            include InstanceMethods

            class_attribute :_aasm_states,            :default => {},                          :instance_accessor => false, :instance_predicate => false
            class_attribute :_aasm_initial_state,     :default => options[:initial],           :instance_accessor => false, :instance_predicate => false
            class_attribute :_aasm_transition_table,  :default => {},                          :instance_accessor => false, :instance_predicate => false
            class_attribute :_aasm_event_table,       :default => {},                          :instance_accessor => false, :instance_predicate => false
            class_attribute :_aasm_state_column,      :default => options[:column] || 'state', :instance_accessor => false, :instance_predicate => false

            before_create :set_initial_state
            after_create  :run_initial_state_actions

            scope :with_state, lambda { |state| where(["#{table_name}.#{self.class._aasm_state_column} = ?", state.to_s]) }
          end
        end
      end

      module InstanceMethods

        def set_initial_state #:nodoc:
          write_attribute self.class._aasm_state_column, self.class._aasm_initial_state.to_s
        end

        def run_initial_state_actions
          initial = self.class._aasm_states[self.class._aasm_initial_state.to_s]
          initial.entering(self)
          initial.entered(self)
        end

        # Returns the current state the object is in, as a Ruby symbol.
        def current_state
          self.send(self.class._aasm_state_column).to_sym
        end

        # Returns what the next state for a given event would be, as a Ruby symbol.
        def next_state_for_event(event)
          ns = next_states_for_event(event)
          ns.empty? ? nil : ns.first.to.to_sym
        end

        def next_states_for_event(event)
          self.class._aasm_transition_table[event.to_sym].select do |s|
            s.from == current_state.to_s
          end
        end

        def run_transition_action(action)
          Symbol === action ? self.method(action).call : action.call(self)
        end
        private :run_transition_action
      end

      module ClassMethods

        # Returns an array of all known states.
        def states
          _aasm_states.keys.collect { |state| state.to_sym }
        end

        # Define an event.  This takes a block which describes all valid transitions
        # for this event.
        #
        # Example:
        #
        # class Order < ActiveRecord::Base
        #   acts_as_state_machine :initial => :open
        #
        #   state :open
        #   state :closed
        #
        #   event :close_order do
        #     transitions :to => :closed, :from => :open
        #   end
        # end
        #
        # +transitions+ takes a hash where <tt>:to</tt> is the state to transition
        # to and <tt>:from</tt> is a state (or Array of states) from which this
        # event can be fired.
        #
        # This creates an instance method used for firing the event.  The method
        # created is the name of the event followed by an exclamation point (!).
        # Example: <tt>order.close_order!</tt>.
        def event(event, opts={}, &block)
          tt = self._aasm_transition_table

          e = SupportingClasses::Event.new(event, opts, tt, &block)
          self._aasm_event_table[event.to_sym] = e
          define_method("#{event.to_s}!") { e.fire(self) }
        end

        # Define a state of the system. +state+ can take an optional Proc object
        # which will be executed every time the system transitions into that
        # state.  The proc will be passed the current object.
        #
        # Example:
        #
        # class Order < ActiveRecord::Base
        #   acts_as_state_machine :initial => :open
        #
        #   state :open
        #   state :closed, Proc.new { |o| Mailer.send_notice(o) }
        # end
        def state(name, opts={})
          state = SupportingClasses::State.new(name, opts)
          self._aasm_states[state.value] = state

          define_method("#{state.name}?") { current_state.to_s == state.value }
        end

      end # module ClassMethods
    end # module StateMachine
  end # module Acts
end # module ScottBarron
