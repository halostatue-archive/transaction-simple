# :title: Transaction::Simple
# :main: Transaction::Simple
#
# == Licence
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#--
# Transaction::Simple
#   Simple object transaction support for Ruby
#   Version 1.2.0
#
# Copyright (c) 2003 - 2004 Austin Ziegler
#
# $Id$
#++
  # Required for Transaction::Simple::ThreadSafe
require 'thread'

  # The "Transaction" namespace can be used for additional transactional
  # support objects and modules.
module Transaction
    # A standard exception for transactional errors.
  class TransactionError < StandardError; end
  class TransactionAborted < Exception; end
  class TransactionCommitted < Exception; end
    # A standard exception for transactional errors involving the acquisition
    # of locks for Transaction::Simple::ThreadSafe.
  class TransactionThreadError < StandardError; end

    # = Transaction::Simple for Ruby
    # Simple object transaction support for Ruby
    #
    # == Introduction
    #
    # Transaction::Simple provides a generic way to add active transactional
    # support to objects. The transaction methods added by this module will
    # work with most objects, excluding those that cannot be
    # <i>Marshal</i>ed (bindings, procedure objects, IO instances, or
    # singleton objects).
    #
    # The transactions supported by Transaction::Simple are not backed
    # transactions; that is, they have nothing to do with any sort of data
    # store. They are "live" transactions occurring in memory and in the
    # object itself. This is to allow "test" changes to be made to an object
    # before making the changes permanent.
    #
    # Transaction::Simple can handle an "infinite" number of transactional
    # levels (limited only by memory). If I open two transactions, commit
    # the first, but abort the second, the object will revert to the
    # original version.
    # 
    # Transaction::Simple supports "named" transactions, so that multiple
    # levels of transactions can be committed, aborted, or rewound by
    # referring to the appropriate name of the transaction. Names may be any
    # object *except* +nil+.
    #
    # Copyright::   Copyright © 2003 - 2004 by Austin Ziegler
    # Version::     1.2
    # Licence::     MIT-Style
    #
    # Thanks to David Black for help with the initial concept that led to
    # this library.
    #
    # == Usage
    #   include 'transaction/simple'
    #
    #   v = "Hello, you."               # => "Hello, you."
    #   v.extend(Transaction::Simple)   # => "Hello, you."
    #
    #   v.start_transaction             # => ... (a Marshal string)
    #   v.transaction_open?             # => true
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #
    #   v.rewind_transaction            # => "Hello, you."
    #   v.transaction_open?             # => true
    #
    #   v.gsub!(/you/, "HAL")           # => "Hello, HAL."
    #   v.abort_transaction             # => "Hello, you."
    #   v.transaction_open?             # => false
    #
    #   v.start_transaction             # => ... (a Marshal string)
    #   v.start_transaction             # => ... (a Marshal string)
    #
    #   v.transaction_open?             # => true
    #   v.gsub!(/you/, "HAL")           # => "Hello, HAL."
    #
    #   v.commit_transaction            # => "Hello, HAL."
    #   v.transaction_open?             # => true
    #   v.abort_transaction             # => "Hello, you."
    #   v.transaction_open?             # => false
    #
    # == Named Transaction Usage
    #   v = "Hello, you."               # => "Hello, you."
    #   v.extend(Transaction::Simple)   # => "Hello, you."
    #   
    #   v.start_transaction(:first)     # => ... (a Marshal string)
    #   v.transaction_open?             # => true
    #   v.transaction_open?(:first)     # => true
    #   v.transaction_open?(:second)    # => false
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   v.rewind_transaction(:first)    # => "Hello, you."
    #   v.transaction_open?             # => true
    #   v.transaction_open?(:first)     # => true
    #   v.transaction_open?(:second)    # => false
    #   
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   v.transaction_name              # => :second
    #   v.abort_transaction(:first)     # => "Hello, you."
    #   v.transaction_open?             # => false
    #   
    #   v.start_transaction(:first)     # => ... (a Marshal string)
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   
    #   v.commit_transaction(:first)    # => "Hello, HAL."
    #   v.transaction_open?             # => false
    #
    # == Block Usage
    #   include 'transaction/simple'
    #
    #   v = "Hello, you."               # => "Hello, you."
    #   Transaction::Simple.start(v) do |tv|
    #       # v has been extended with Transaction::Simple and an unnamed
    #       # transaction has been started.
    #     tv.transaction_open?          # => true
    #     tv.gsub!(/you/, "world")      # => "Hello, world."
    #
    #     tv.rewind_transaction         # => "Hello, you."
    #     tv.transaction_open?          # => true
    #
    #     tv.gsub!(/you/, "HAL")        # => "Hello, HAL."
    #       # The following breaks out of the transaction block after
    #       # aborting the transaction.
    #     tv.abort_transaction          # => "Hello, you."
    #   end
    #     # v still has Transaction::Simple applied from here on out.
    #   v.transaction_open?             # => false
    #
    #   Transaction::Simple.start(v) do |tv|
    #     tv.start_transaction          # => ... (a Marshal string)
    #
    #     tv.transaction_open?          # => true
    #     tv.gsub!(/you/, "HAL")        # => "Hello, HAL."
    #
    #       # If #commit_transaction were called without having started a
    #       # second transaction, then it would break out of the transaction
    #       # block after committing the transaction.
    #     tv.commit_transaction         # => "Hello, HAL."
    #     tv.transaction_open?          # => true
    #     tv.abort_transaction          # => "Hello, you."
    #   end
    #   v.transaction_open?             # => false
    #
    # == Named Transaction Usage
    #   v = "Hello, you."               # => "Hello, you."
    #   v.extend(Transaction::Simple)   # => "Hello, you."
    #   
    #   v.start_transaction(:first)     # => ... (a Marshal string)
    #   v.transaction_open?             # => true
    #   v.transaction_open?(:first)     # => true
    #   v.transaction_open?(:second)    # => false
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   v.rewind_transaction(:first)    # => "Hello, you."
    #   v.transaction_open?             # => true
    #   v.transaction_open?(:first)     # => true
    #   v.transaction_open?(:second)    # => false
    #   
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   v.transaction_name              # => :second
    #   v.abort_transaction(:first)     # => "Hello, you."
    #   v.transaction_open?             # => false
    #   
    #   v.start_transaction(:first)     # => ... (a Marshal string)
    #   v.gsub!(/you/, "world")         # => "Hello, world."
    #   v.start_transaction(:second)    # => ... (a Marshal string)
    #   v.gsub!(/world/, "HAL")         # => "Hello, HAL."
    #   
    #   v.commit_transaction(:first)    # => "Hello, HAL."
    #   v.transaction_open?             # => false
    #
    # == Contraindications
    #
    # While Transaction::Simple is very useful, it has some severe
    # limitations that must be understood. Transaction::Simple:
    #
    # * uses Marshal. Thus, any object which cannot be <i>Marshal</i>ed
    #   cannot use Transaction::Simple.
    # * does not manage resources. Resources external to the object and its
    #   instance variables are not managed at all. However, all instance
    #   variables and objects "belonging" to those instance variables are
    #   managed. If there are object reference counts to be handled,
    #   Transaction::Simple will probably cause problems.
    # * is not inherently thread-safe. In the ACID ("atomic, consistent,
    #   isolated, durable") test, Transaction::Simple provides CD, but it is
    #   up to the user of Transaction::Simple to provide isolation and
    #   atomicity. Transactions should be considered "critical sections" in
    #   multi-threaded applications. If thread safety and atomicity is
    #   absolutely required, use Transaction::Simple::ThreadSafe, which uses
    #   a Mutex object to synchronize the accesses on the object during the
    #   transactional operations.
    # * does not necessarily maintain Object#__id__ values on rewind or
    #   abort. This may change for future versions that will be Ruby 1.8 or
    #   better *only*. Certain objects that support #replace will maintain
    #   Object#__id__.
    # * Can be a memory hog if you use many levels of transactions on many
    #   objects.
    #
  module Simple
    VERSION = '1.2.0'

      # Sets the Transaction::Simple debug object. It must respond to #<<.
      # Sets the transaction debug object. Debugging will be performed
      # automatically if there's a debug object. The generic transaction
      # error class.
    def self.debug_io=(io)
      raise TransactionError, "Transaction Error: the transaction debug object must respond to #<<" unless io.respond_to?(:<<)
      @tdi = io
    end

      # Returns the Transaction::Simple debug object. It must respond to
      # #<<.
    def self.debug_io
      @tdi
    end

      # If +name+ is +nil+ (default), then returns +true+ if there is
      # currently a transaction open.
      #
      # If +name+ is specified, then returns +true+ if there is currently a
      # transaction that responds to +name+ open.
    def transaction_open?(name = nil)
      if name.nil?
        Transaction::Simple.debug_io << "Transaction [#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" unless Transaction::Simple.debug_io.nil?
        return (not @__transaction_checkpoint__.nil?)
      else
        Transaction::Simple.debug_io << "Transaction(#{name.inspect}) [#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" unless Transaction::Simple.debug_io.nil?
        return ((not @__transaction_checkpoint__.nil?) and @__transaction_names__.include?(name))
      end
    end

      # Returns the current name of the transaction. Transactions not
      # explicitly named are named +nil+.
    def transaction_name
      raise TransactionError, "Transaction Error: No transaction open." if @__transaction_checkpoint__.nil?
      Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} Transaction Name: #{@__transaction_names__[-1].inspect}\n" unless Transaction::Simple.debug_io.nil?
      @__transaction_names__[-1]
    end

      # Starts a transaction. Stores the current object state. If a
      # transaction name is specified, the transaction will be named.
      # Transaction names must be unique. Transaction names of +nil+ will be
      # treated as unnamed transactions.
    def start_transaction(name = nil)
      @__transaction_level__ ||= 0
      @__transaction_names__ ||= []

      if name.nil?
        @__transaction_names__ << nil
        ss = ""
      else
        raise TransactionError, "Transaction Error: Named transactions must be unique." if @__transaction_names__.include?(name)
        @__transaction_names__ << name
        ss = "(#{name.inspect})"
      end

      @__transaction_level__ += 1

      Transaction::Simple.debug_io << "#{'>' * @__transaction_level__} Start Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?

      @__transaction_checkpoint__ = Marshal.dump(self)
    end

      # Rewinds the transaction. If +name+ is specified, then the
      # intervening transactions will be aborted and the named transaction
      # will be rewound. Otherwise, only the current transaction is rewound.
    def rewind_transaction(name = nil)
      raise TransactionError, "Transaction Error: Cannot rewind. There is no current transaction." if @__transaction_checkpoint__.nil?
      if name.nil?
        __rewind_this_transaction
        ss = ""
      else
        raise TransactionError, "Transaction Error: Cannot rewind to transaction #{name.inspect} because it does not exist." unless @__transaction_names__.include?(name)
        ss = "(#{name})"

        while @__transaction_names__[-1] != name
          @__transaction_checkpoint__ = __rewind_this_transaction
          Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} Rewind Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
          @__transaction_level__ -= 1
          @__transaction_names__.pop
        end
        __rewind_this_transaction
      end
      Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} Rewind Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
      self
    end

      # Aborts the transaction. Resets the object state to what it was
      # before the transaction was started and closes the transaction. If
      # +name+ is specified, then the intervening transactions and the named
      # transaction will be aborted. Otherwise, only the current transaction
      # is aborted.
      #
      # If the current or named transaction has been started by a block
      # (Transaction::Simple.start), then the execution of the block will be
      # halted with +break+ +self+.
    def abort_transaction(name = nil)
      raise TransactionError, "Transaction Error: Cannot abort. There is no current transaction." if @__transaction_checkpoint__.nil?

        # Check to see if we are trying to abort a transaction that is
        # outside of the current transaction block. Otherwise, raise
        # TransactionAborted if they are the same.
      if @__transaction_block__ and name
        nix = @__transaction_names__.index(name) + 1
        raise TransactionError, "Transaction Error: Cannot abort a transaction outside of this execution block." if nix < @__transaction_block__

        raise TransactionAborted if @__transaction_block__ == nix
      end

      raise TransactionAborted if @__transaction_block__ == @__transaction_level__

      if name.nil?
        __abort_transaction(name)
      else
        raise TransactionError, "Transaction Error: Cannot abort nonexistant transaction #{name.inspect}." unless @__transaction_names__.include?(name)

        __abort_transaction(name) while @__transaction_names__.include?(name)
      end
      self
    end

      # If +name+ is +nil+ (default), the current transaction level is
      # closed out and the changes are committed.
      #
      # If +name+ is specified and +name+ is in the list of named
      # transactions, then all transactions are closed and committed until
      # the named transaction is reached.
    def commit_transaction(name = nil)
      raise TransactionError, "Transaction Error: Cannot commit. There is no current transaction." if @__transaction_checkpoint__.nil?

        # Check to see if we are trying to commit a transaction that is
        # outside of the current transaction block. Otherwise, raise
        # TransactionCommitted if they are the same.
      if @__transaction_block__ and name
        nix = @__transaction_names__.index(name) + 1
        raise TransactionError, "Transaction Error: Cannot commit a transaction outside of this execution block." if nix < @__transaction_block__

        raise TransactionCommitted if @__transaction_block__ == nix
      end

      raise TransactionCommitted if @__transaction_block__ == @__transaction_level__

      if name.nil?
        ss = ""
        __commit_transaction
        Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} Commit Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
      else
        raise TransactionError, "Transaction Error: Cannot commit nonexistant transaction #{name.inspect}." unless @__transaction_names__.include?(name)
        ss = "(#{name})"

        while @__transaction_names__[-1] != name
          Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} Commit Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
          __commit_transaction
        end
        Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} Commit Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
        __commit_transaction
      end

      self
    end

      # Alternative method for calling the transaction methods. An optional
      # name can be specified for named transaction support.
      #
      # #transaction(:start)::  #start_transaction
      # #transaction(:rewind):: #rewind_transaction
      # #transaction(:abort)::  #abort_transaction
      # #transaction(:commit):: #commit_transaction
      # #transaction(:name)::   #transaction_name
      # #transaction::          #transaction_open?
    def transaction(action = nil, name = nil)
      case action
      when :start
        start_transaction(name)
      when :rewind
        rewind_transaction(name)
      when :abort
        abort_transaction(name)
      when :commit
        commit_transaction(name)
      when :name
        transaction_name
      when nil
        transaction_open?(name)
      end
    end

    class << self
      def __common_start(name, vars, &block)
        raise TransactionError, "Transaction Error: Cannot start a transaction with no objects." if vars.empty?

        if block
          begin
            vlevel = {}

            vars.each do |vv|
              vv.extend(Transaction::Simple)
              vv.start_transaction(name)
              vlevel[vv.__id__] = vv.instance_variable_get(:@__transaction_level__)
              vv.instance_variable_set(:@__transaction_block__, vlevel[vv.__id__])
            end

            yield *vars
          rescue TransactionAborted
            vars.each do |vv|
              if name.nil? and vv.transaction_open?
                loop do
                  tlevel = vv.instance_variable_get(:@__transaction_level__) || -1
                  vv.instance_variable_set(:@__transaction_block__, -1)
                  break if tlevel < vlevel[vv.__id__]
                  vv.abort_transaction if vv.transaction_open?
                end
              elsif vv.transaction_open?(name)
                vv.instance_variable_set(:@__transaction_block__, -1)
                vv.abort_transaction(name)
              end
            end
          rescue TransactionCommitted
            nil
          ensure
            vars.each do |vv|
              if name.nil? and vv.transaction_open?
                loop do
                  tlevel = vv.instance_variable_get(:@__transaction_level__) || -1
                  break if tlevel < vlevel[vv.__id__]
                  vv.instance_variable_set(:@__transaction_block__, -1)
                  vv.commit_transaction if vv.transaction_open?
                end
              elsif vv.transaction_open?(name)
                vv.instance_variable_set(:@__transaction_block__, -1)
                vv.commit_transaction(name)
              end
            end
          end
        else
          vars.each do |vv|
            vv.extend(Transaction::Simple)
            vv.start_transaction(name)
          end
        end
      end
      private :__common_start

      def start_named(name, *vars, &block)
        __common_start(name, vars, &block)
      end

      def start(*vars, &block)
        __common_start(nil, vars, &block)
      end
    end

    def __abort_transaction(name = nil) #:nodoc:
      @__transaction_checkpoint__ = __rewind_this_transaction

      if name.nil?
        ss = ""
      else
        ss = "(#{name.inspect})"
      end

      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} Abort Transaction#{ss}\n" unless Transaction::Simple.debug_io.nil?
      @__transaction_level__ -= 1
      @__transaction_names__.pop
      if @__transaction_level__ < 1
        @__transaction_level__ = 0
        @__transaction_names__ = []
      end
    end

    TRANSACTION_CHECKPOINT  = "@__transaction_checkpoint__" #:nodoc:
    SKIP_TRANSACTION_VARS   = [TRANSACTION_CHECKPOINT, "@__transaction_level__"] #:nodoc:

    def __rewind_this_transaction #:nodoc:
      r = Marshal.restore(@__transaction_checkpoint__)

      begin
        self.replace(r) if respond_to?(:replace)
      rescue
        nil
      end

      r.instance_variables.each do |i|
        next if SKIP_TRANSACTION_VARS.include?(i)
        if respond_to?(:instance_variable_get)
          instance_variable_set(i, r.instance_variable_get(i))
        else
          instance_eval(%q|#{i} = r.instance_eval("#{i}")|)
        end
      end

      if respond_to?(:instance_variable_get)
        return r.instance_variable_get(TRANSACTION_CHECKPOINT)
      else
        return r.instance_eval(TRANSACTION_CHECKPOINT)
      end
    end

    def __commit_transaction #:nodoc:
      if respond_to?(:instance_variable_get)
        @__transaction_checkpoint__ = Marshal.restore(@__transaction_checkpoint__).instance_variable_get(TRANSACTION_CHECKPOINT)
      else
        @__transaction_checkpoint__ = Marshal.restore(@__transaction_checkpoint__).instance_eval(TRANSACTION_CHECKPOINT)
      end

      @__transaction_level__ -= 1
      @__transaction_names__.pop
      if @__transaction_level__ < 1
        @__transaction_level__ = 0
        @__transaction_names__ = []
      end
    end

    private :__abort_transaction, :__rewind_this_transaction, :__commit_transaction

      # = Transaction::Simple::ThreadSafe
      # Thread-safe simple object transaction support for Ruby.
      # Transaction::Simple::ThreadSafe is used in the same way as
      # Transaction::Simple. Transaction::Simple::ThreadSafe uses a Mutex
      # object to ensure atomicity at the cost of performance in threaded
      # applications.
      #
      # Transaction::Simple::ThreadSafe will not wait to obtain a lock; if the
      # lock cannot be obtained immediately, a
      # Transaction::TransactionThreadError will be raised.
      #
      # Thanks to Mauricio Fernández for help with getting this part working.
    module ThreadSafe
      VERSION = '1.2.0'

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
              raise TransactionThreadError, "Transaction Error: Cannot obtain lock for ##{meth}"
            end
          ensure
            @__transaction_mutex__.unlock
          end
        EOS
      end
    end
  end
end
