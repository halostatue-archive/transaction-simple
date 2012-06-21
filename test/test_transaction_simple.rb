# -*- ruby encoding: utf-8 -*-

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'transaction/simple'
require 'test/unit'

module Transaction::Simple::Test
  class TransactionSimple < Test::Unit::TestCase #:nodoc:
    VALUE = "Now is the time for all good men to come to the aid of their country."

    class Value
      def initialize
        @value = VALUE.dup
      end

      def method_missing(meth, *args, &block)
        @value.__send__(meth, *args, &block)
      end

      def ==(other)
        other == @value
      end

      def to_str
        @value
      end
    end

    def setup
      @value = Value.new
      @value.extend(Transaction::Simple)
    end

    def test_extended
      assert_respond_to(@value, :start_transaction)
    end

    def test_started
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
    end

    def test_rewind
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_nothing_raised { @value.rewind_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_abort
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(false, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_commit
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.commit_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.commit_transaction }
      assert_equal(false, @value.transaction_open?)
      assert_not_equal(VALUE, @value)
    end

    def test_multilevel
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_nothing_raised { @value.gsub!(/country/, 'nation-state') }
      assert_nothing_raised { @value.commit_transaction }
      assert_equal(VALUE.gsub(/men/, 'women').gsub(/country/, 'nation-state'), @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(VALUE, @value)
    end

    def test_multilevel_named
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.transaction_name }
      assert_nothing_raised { @value.start_transaction(:first) } # 1
      assert_raises(Transaction::TransactionError) { @value.start_transaction(:first) }
      assert_equal(true, @value.transaction_open?)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(:first, @value.transaction_name)
      assert_nothing_raised { @value.start_transaction } # 2
      assert_not_equal(:first, @value.transaction_name)
      assert_equal(nil, @value.transaction_name)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction(:second) }
      assert_nothing_raised { @value.abort_transaction(:first) }
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised do
        @value.start_transaction(:first)
        @value.gsub!(/men/, 'women')
        @value.start_transaction(:second)
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_nothing_raised { @value.abort_transaction(:second) }
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised do
        @value.start_transaction(:second)
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction(:foo) }
      assert_nothing_raised { @value.rewind_transaction(:second) }
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised do
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_raises(Transaction::TransactionError) { @value.commit_transaction(:foo) }
      assert_nothing_raised { @value.commit_transaction(:first) }
      assert_equal(VALUE.gsub(/men/, 'sentients'), @value)
      assert_equal(false, @value.transaction_open?)
    end

    def test_block
      Transaction::Simple.start(@value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        tv.abort_transaction
        flunk("Failed to abort the transaction.")
      end
      assert_equal(false, @value.transaction_open?)
      assert_equal(VALUE, @value)

      @value = VALUE.dup
      Transaction::Simple.start(@value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        tv.commit_transaction
        flunk("Failed to commit the transaction.")
      end
      assert_equal(false, @value.transaction_open?)
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
    end

    def test_named_block
      Transaction::Simple.start_named(:first, @value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_equal(true, tv.transaction_open?(:first))
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        tv.abort_transaction
        flunk("Failed to abort the transaction.")
      end
      assert_equal(false, @value.transaction_open?)
      assert_equal(false, @value.transaction_open?(:first))
      assert_equal(VALUE, @value)

      @value = VALUE.dup
      Transaction::Simple.start_named(:first, @value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_equal(true, tv.transaction_open?(:first))
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        tv.commit_transaction
        flunk("Failed to commit the transaction.")
      end
      assert_equal(false, @value.transaction_open?)
      assert_equal(false, @value.transaction_open?(:first))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
    end

    def test_named_block_error
      @value.start_transaction(:first)
      Transaction::Simple.start_named(:second, @value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_equal(true, tv.transaction_open?(:first))
        assert_equal(true, tv.transaction_open?(:second))
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        assert_raises(Transaction::TransactionError) do
          tv.abort_transaction(:first)
        end
      end
      assert_equal(true, @value.transaction_open?)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(false, @value.transaction_open?(:second))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised { @value.abort_transaction(:first) }
      assert_equal(VALUE, @value)

      @value.start_transaction(:first)
      Transaction::Simple.start_named(:second, @value) do |tv|
        assert_equal(true, tv.transaction_open?)
        assert_equal(true, tv.transaction_open?(:first))
        assert_equal(true, tv.transaction_open?(:second))
        assert_nothing_raised { tv.gsub!(/men/, 'women') }
        assert_equal(VALUE.gsub(/men/, 'women'), tv)
        assert_raises(Transaction::TransactionError) do
          tv.commit_transaction(:first)
        end
      end
      assert_equal(true, @value.transaction_open?)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(false, @value.transaction_open?(:second))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised { @value.abort_transaction(:first) }
      assert_equal(VALUE, @value)
    end

    def test_multivar_block
      a = VALUE.dup
      b = a.dup

      Transaction::Simple.start(a, b) do |ta, tb|
        assert_equal(true, ta.transaction_open?)
        assert_equal(true, tb.transaction_open?)
        ta.abort_transaction
        flunk("Failed to abort the transaction.")
      end
      assert_equal(false, a.transaction_open?)
      assert_equal(false, b.transaction_open?)

      Transaction::Simple.start(a, b) do |ta, tb|
        assert_equal(true, ta.transaction_open?)
        assert_equal(true, tb.transaction_open?)
        ta.commit_transaction
        flunk("Failed to commit the transaction.")
      end
      assert_equal(false, a.transaction_open?)
      assert_equal(false, b.transaction_open?)
    end

    def test_multilevel_block
      Transaction::Simple.start_named(:outer, @value) do |tv0|
        assert_equal(1, tv0.instance_variable_get(:@__transaction_level__))
        assert_equal(true, tv0.transaction_open?(:outer))
        Transaction::Simple.start_named(:inner, tv0) do |tv1|
          assert_equal(2, tv0.instance_variable_get(:@__transaction_level__))
          assert_equal(true, tv1.transaction_open?(:inner))
          tv1.abort_transaction
          flunk("Failed to abort the transaction.")
        end
        assert_equal(false, tv0.transaction_open?(:inner))
        assert_equal(true, tv0.transaction_open?(:outer))

        tv0.commit_transaction
        flunk("Failed to commit the transaction.")
      end
      assert_equal(false, @value.transaction_open?(:inner))
      assert_equal(false, @value.transaction_open?(:outer))
    end

    def test_array
      assert_nothing_raised do
        @orig = ["first", "second", "third"]
        @value = ["first", "second", "third"]
        @value.extend(Transaction::Simple)
      end
      assert_equal(@orig, @value)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value[1].gsub!(/second/, "fourth") }
      assert_not_equal(@orig, @value)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(@orig, @value)
    end

    def test_instance_var
      @value = VALUE.dup
      @value.extend(Transaction::Simple)
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value.instance_variable_set("@foo", "bar")
      @value.rewind_transaction
      assert_equal(false, @value.instance_variables.include?("@foo"))
    end
  end
end

# vim: syntax=ruby
