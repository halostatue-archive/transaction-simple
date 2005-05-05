require 'transaction/simple'
require 'thread'

class Transaction::TransactionThreadError < StandardError
end

  # = Transaction::Simple::ThreadSafe
  # Thread-safe simple object transaction support for Ruby.
  # Transaction::Simple::ThreadSafe is used in the same way as
  # Transaction::Simple. Transaction::Simple::ThreadSafe uses a Mutex object
  # to ensure atomicity at the cost of performance in threaded applications.
  #
  # Transaction::Simple::ThreadSafe will not wait to obtain a lock; if the
  # lock cannot be obtained immediately, a
  # Transaction::TransactionThreadError will be raised.
  #
  # Thanks to Mauricio Fernández for help with getting this part working.
  #
  # Threadsafe transactions can be used in any place that normal
  # transactions would. The main difference would be in setup:
  #
  #   require 'transaction/simple/threadsafe'
  #
  #   x = "Hello, you."
  #   x.extend(Transaction::Simple::ThreadSafe) # Threadsafe
  #
  #   y = "Hello, you."
  #   y.extend(Transaction::Simple)             # Not threadsafe
module Transaction::Simple::ThreadSafe
  include Transaction::Simple

  SKIP_TRANSACTION_VARS = Transaction::Simple::SKIP_TRANSACTION_VARS.dup #:nodoc:
  SKIP_TRANSACTION_VARS << "@__transaction_mutex__"

  Transaction::Simple.instance_methods(false) do |meth|
    next if meth == "transaction"
    arg = "(name = nil)" unless meth == "transaction_name"
    module_eval <<-EOS
    def #{meth}#{arg}
      if (@__transaction_mutex__ ||= Mutex.new).try_lock
        result = super
        @__transaction_mutex__.unlock
        return result
      else
        raise TransactionThreadError, Messages[:cannot_obtain_transaction_lock] % meth
      end
    ensure
      @__transaction_mutex__.unlock
    end
    EOS
  end
end
