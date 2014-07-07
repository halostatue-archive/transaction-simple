# -*- ruby encoding: utf-8 -*-

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'transaction/simple'
require 'minitest'

module Transaction::Simple::Test
  class BrokenGraph < Minitest::Test #:nodoc:
    class Child
      attr_accessor :parent
    end

    class BrokenParent
      include Transaction::Simple

      attr_reader :children
      def initialize
        @children = []
      end

      def <<(child)
        child.parent = self
        @children << child
      end
    end

    class FixedParent < BrokenParent
      # Reconnect the restored children to me, instead of to the bogus me
      # that was restored to them by Marshal::load.
      def _post_transaction_rewind
        @children.each { |child| child.parent = self }
      end
    end

    def test_broken_graph
      parent = BrokenParent.new
      parent << Child.new
      assert_equal(parent.object_id, parent.children[0].parent.object_id)
      parent.start_transaction
      parent << Child.new
      assert_equal(parent.object_id, parent.children[1].parent.object_id)
      parent.abort_transaction
      refute_equal(parent.object_id, parent.children[0].parent.object_id)
    end

    def test_fixed_graph
      parent = FixedParent.new
      parent << Child.new
      assert_equal(parent.object_id, parent.children[0].parent.object_id)
      parent.start_transaction
      parent << Child.new
      assert_equal(parent.object_id, parent.children[1].parent.object_id)
      parent.abort_transaction
      assert_equal(parent.object_id, parent.children[0].parent.object_id)
    end
  end
end

# vim: syntax=ruby
