# -*- ruby encoding: utf-8 -*-

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'transaction/simple/threadsafe'
require 'minitest'

module Transaction::Simple::Test
  class ThreadSafe < Minitest::Test #:nodoc:
    VALUE = "Now is the time for all good men to come to the aid of their country."

    def setup
      @value = VALUE.dup
      @value.extend(Transaction::Simple::ThreadSafe)
    end

    def test_extended
      assert_respond_to(@value, :start_transaction)
    end

    def test_started
      assert_equal(false, @value.transaction_open?)
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
    end

    def test_rewind
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction }
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value.gsub!(/men/, 'women')
      refute_equal(VALUE, @value)
      @value.rewind_transaction
      assert_equal(true, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_abort
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction }
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value.gsub!(/men/, 'women')
      refute_equal(VALUE, @value)
      @value.abort_transaction
      assert_equal(false, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_commit
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.commit_transaction }
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value.gsub!(/men/, 'women')
      refute_equal(VALUE, @value)
      assert_equal(true, @value.transaction_open?)
      @value.commit_transaction
      assert_equal(false, @value.transaction_open?)
      refute_equal(VALUE, @value)
    end

    def test_multilevel
      assert_equal(false, @value.transaction_open?)
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value.gsub!(/men/, 'women')
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_equal(true, @value.transaction_open?)
      @value.start_transaction
      @value.gsub!(/country/, 'nation-state')
      @value.commit_transaction
      assert_equal(VALUE.gsub(/men/, 'women').gsub(/country/, 'nation-state'), @value)
      assert_equal(true, @value.transaction_open?)
      @value.abort_transaction
      assert_equal(VALUE, @value)
    end

    def test_multilevel_named
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.transaction_name }
      @value.start_transaction(:first)
      assert_raises(Transaction::TransactionError) { @value.start_transaction(:first) }
      assert_equal(true, @value.transaction_open?)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(:first, @value.transaction_name)
      @value.start_transaction
      refute_equal(:first, @value.transaction_name)
      assert_equal(nil, @value.transaction_name)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction(:second) }
      @value.abort_transaction(:first)
      assert_equal(false, @value.transaction_open?)
      @value.start_transaction(:first)
      @value.gsub!(/men/, 'women')
      @value.start_transaction(:second)
      @value.gsub!(/women/, 'people')
      @value.start_transaction
      @value.gsub!(/people/, 'sentients')
      @value.abort_transaction(:second)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      @value.start_transaction(:second)
      @value.gsub!(/women/, 'people')
      @value.start_transaction
      @value.gsub!(/people/, 'sentients')
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction(:foo) }
      @value.rewind_transaction(:second)
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      @value.gsub!(/women/, 'people')
      @value.start_transaction
      @value.gsub!(/people/, 'sentients')
      assert_raises(Transaction::TransactionError) { @value.commit_transaction(:foo) }
      @value.commit_transaction(:first)
      assert_equal(VALUE.gsub(/men/, 'sentients'), @value)
      assert_equal(false, @value.transaction_open?)
    end

    def test_array
      @orig = ["first", "second", "third"]
      @value = ["first", "second", "third"]
      @value.extend(Transaction::Simple::ThreadSafe)
      assert_equal(@orig, @value)
      @value.start_transaction
      assert_equal(true, @value.transaction_open?)
      @value[1].gsub!(/second/, "fourth")
      refute_equal(@orig, @value)
      @value.abort_transaction
      assert_equal(@orig, @value)
    end
  end
end

# vim: syntax=ruby
