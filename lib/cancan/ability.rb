module CanCan
  module Ability
    def self.included(base)
      base.extend ClassMethods
    end
    
    def can?(original_action, target)
      (self.class.can_history || []).reverse.each do |can_action, can_target, can_block|
        possible_actions_for(original_action).each do |action|
          if (can_action == :manage || can_action == action) && (can_target == :all || can_target == target || target.kind_of?(can_target))
            if can_block.nil?
              return true
            else
              block_args = []
              block_args << action if can_action == :manage
              block_args << (target.class == Class ? target : target.class) if can_target == :all
              block_args << (target.class == Class ? nil : target)
              return can_block.call(*block_args)
            end
          end
        end
      end
      false
    end
    
    def possible_actions_for(initial_action)
      actions = [initial_action]
      (self.class.aliased_actions || []).each do |target, aliases|
        actions += possible_actions_for(target) if aliases.include? initial_action
      end
      actions
    end
    
    module ClassMethods
      attr_reader :can_history
      attr_reader :aliased_actions
      
      def can(action, target, &block)
        @can_history ||= []
        @can_history << [action, target, block]
      end
      
      def alias_action(*args)
        @aliased_actions ||= {}
        target = args.pop[:to]
        @aliased_actions[target] = args
      end
    end
  end
end