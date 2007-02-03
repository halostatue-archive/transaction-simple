# :title: Transaction::Simple -- Active Object Transaction Support for Ruby
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
# Simple object transaction support for Ruby
# http://rubyforge.org/projects/trans-simple/
#   Version 1.4.0
#
# Licensed under a MIT-style licence. See Licence.txt in the main
# distribution for full licensing information.
#
# Copyright (c) 2003 - 2007 Austin Ziegler
#
# $Id$
#++

# The "Transaction" namespace can be used for additional transaction support
# objects and modules.
module Transaction
  # A standard exception for transaction errors.
  class TransactionError < StandardError; end
  # The TransactionAborted exception is used to indicate when a transaction
  # has been aborted in the block form.
  class TransactionAborted < Exception; end
  # The TransactionCommitted exception is used to indicate when a
  # transaction has been committed in the block form.
  class TransactionCommitted < Exception; end

  te = "Transaction Error: %s"

  Messages = {
    :bad_debug_object =>
    te % "the transaction debug object must respond to #<<.",
      :unique_names =>
    te % "named transactions must be unique.",
      :no_transaction_open =>
    te % "no transaction open.",
      :cannot_rewind_no_transaction =>
    te % "cannot rewind; there is no current transaction.",
      :cannot_rewind_named_transaction =>
    te % "cannot rewind to transaction %s because it does not exist.",
      :cannot_rewind_transaction_before_block =>
    te % "cannot rewind a transaction started before the execution block.",
      :cannot_abort_no_transaction =>
    te % "cannot abort; there is no current transaction.",
      :cannot_abort_transaction_before_block =>
    te % "cannot abort a transaction started before the execution block.",
      :cannot_abort_named_transaction =>
    te % "cannot abort nonexistant transaction %s.",
      :cannot_commit_no_transaction =>
    te % "cannot commit; there is no current transaction.",
      :cannot_commit_transaction_before_block =>
    te % "cannot commit a transaction started before the execution block.",
      :cannot_commit_named_transaction =>
    te % "cannot commit nonexistant transaction %s.",
      :cannot_start_empty_block_transaction =>
    te % "cannot start a block transaction with no objects.",
      :cannot_obtain_transaction_lock =>
    te % "cannot obtain transaction lock for #%s.",
  }
end

# = Transaction::Simple for Ruby
# Simple object transaction support for Ruby
#
# == Introduction
# Transaction::Simple provides a generic way to add active transaction
# support to objects. The transaction methods added by this module will
# work with most objects, excluding those that cannot be
# <i>Marshal</i>ed (bindings, procedure objects, IO instances, or
# singleton objects).
#
# The transactions supported by Transaction::Simple are not backed
# transactions; they are not associated with any sort of data store.
# They are "live" transactions occurring in memory and in the object
# itself. This is to allow "test" changes to be made to an object
# before making the changes permanent.
#
# Transaction::Simple can handle an "infinite" number of transaction
# levels (limited only by memory). If I open two transactions, commit
# the second, but abort the first, the object will revert to the
# original version.
# 
# Transaction::Simple supports "named" transactions, so that multiple
# levels of transactions can be committed, aborted, or rewound by
# referring to the appropriate name of the transaction. Names may be any
# object *except* +nil+. As with Hash keys, String names will be
# duplicated and frozen before using.
#
# Copyright::   Copyright (c) 2003 - 2007 by Austin Ziegler
# Version::     1.4.0
# Licence::     MIT-Style; see Licence.txt
#
# Thanks to David Black, Mauricio Fernández, Patrick Hurley, Pit Capitain,
# and Matz for their assistance with this library.
#
# == Usage
#   include 'transaction/simple'
#
#   v = "Hello, you."               # -> "Hello, you."
#   v.extend(Transaction::Simple)   # -> "Hello, you."
#
#   v.start_transaction             # -> ... (a Marshal string)
#   v.transaction_open?             # -> true
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#
#   v.rewind_transaction            # -> "Hello, you."
#   v.transaction_open?             # -> true
#
#   v.gsub!(/you/, "HAL")           # -> "Hello, HAL."
#   v.abort_transaction             # -> "Hello, you."
#   v.transaction_open?             # -> false
#
#   v.start_transaction             # -> ... (a Marshal string)
#   v.start_transaction             # -> ... (a Marshal string)
#
#   v.transaction_open?             # -> true
#   v.gsub!(/you/, "HAL")           # -> "Hello, HAL."
#
#   v.commit_transaction            # -> "Hello, HAL."
#   v.transaction_open?             # -> true
#   v.abort_transaction             # -> "Hello, you."
#   v.transaction_open?             # -> false
#
# == Named Transaction Usage
#   v = "Hello, you."               # -> "Hello, you."
#   v.extend(Transaction::Simple)   # -> "Hello, you."
#   
#   v.start_transaction(:first)     # -> ... (a Marshal string)
#   v.transaction_open?             # -> true
#   v.transaction_open?(:first)     # -> true
#   v.transaction_open?(:second)    # -> false
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   v.rewind_transaction(:first)    # -> "Hello, you."
#   v.transaction_open?             # -> true
#   v.transaction_open?(:first)     # -> true
#   v.transaction_open?(:second)    # -> false
#   
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   v.transaction_name              # -> :second
#   v.abort_transaction(:first)     # -> "Hello, you."
#   v.transaction_open?             # -> false
#   
#   v.start_transaction(:first)     # -> ... (a Marshal string)
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   
#   v.commit_transaction(:first)    # -> "Hello, HAL."
#   v.transaction_open?             # -> false
#
# == Block Usage
#   v = "Hello, you."               # -> "Hello, you."
#   Transaction::Simple.start(v) do |tv|
#       # v has been extended with Transaction::Simple and an unnamed
#       # transaction has been started.
#     tv.transaction_open?          # -> true
#     tv.gsub!(/you/, "world")      # -> "Hello, world."
#
#     tv.rewind_transaction         # -> "Hello, you."
#     tv.transaction_open?          # -> true
#
#     tv.gsub!(/you/, "HAL")        # -> "Hello, HAL."
#       # The following breaks out of the transaction block after
#       # aborting the transaction.
#     tv.abort_transaction          # -> "Hello, you."
#   end
#     # v still has Transaction::Simple applied from here on out.
#   v.transaction_open?             # -> false
#
#   Transaction::Simple.start(v) do |tv|
#     tv.start_transaction          # -> ... (a Marshal string)
#
#     tv.transaction_open?          # -> true
#     tv.gsub!(/you/, "HAL")        # -> "Hello, HAL."
#
#       # If #commit_transaction were called without having started a
#       # second transaction, then it would break out of the transaction
#       # block after committing the transaction.
#     tv.commit_transaction         # -> "Hello, HAL."
#     tv.transaction_open?          # -> true
#     tv.abort_transaction          # -> "Hello, you."
#   end
#   v.transaction_open?             # -> false
#
# == Named Transaction Usage
#   v = "Hello, you."               # -> "Hello, you."
#   v.extend(Transaction::Simple)   # -> "Hello, you."
#   
#   v.start_transaction(:first)     # -> ... (a Marshal string)
#   v.transaction_open?             # -> true
#   v.transaction_open?(:first)     # -> true
#   v.transaction_open?(:second)    # -> false
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   v.rewind_transaction(:first)    # -> "Hello, you."
#   v.transaction_open?             # -> true
#   v.transaction_open?(:first)     # -> true
#   v.transaction_open?(:second)    # -> false
#   
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   v.transaction_name              # -> :second
#   v.abort_transaction(:first)     # -> "Hello, you."
#   v.transaction_open?             # -> false
#   
#   v.start_transaction(:first)     # -> ... (a Marshal string)
#   v.gsub!(/you/, "world")         # -> "Hello, world."
#   v.start_transaction(:second)    # -> ... (a Marshal string)
#   v.gsub!(/world/, "HAL")         # -> "Hello, HAL."
#   
#   v.commit_transaction(:first)    # -> "Hello, HAL."
#   v.transaction_open?             # -> false
#
# == Thread Safety
# Threadsafe version of Transaction::Simple and
# Transaction::Simple::Group exist; these are loaded from
# 'transaction/simple/threadsafe' and
# 'transaction/simple/threadsafe/group', respectively, and are
# represented in Ruby code as Transaction::Simple::ThreadSafe and
# Transaction::Simple::ThreadSafe::Group, respectively.
#
# == Contraindications
# While Transaction::Simple is very useful, it has limitations that must be
# understood prior to using it. Transaction::Simple:
#
# * uses Marshal. Thus, any object which cannot be Marshal-ed cannot use
#   Transaction::Simple. In my experience, this affects singleton objects
#   more often than any other object.
# * does not manage external resources. Resources external to the object and
#   its instance variables are not managed at all. However, all instance
#   variables and objects "belonging" to those instance variables are
#   managed. If there are object reference counts to be handled,
#   Transaction::Simple will probably cause problems.
# * is not thread-safe. In the ACID ("atomic, consistent, isolated,
#   durable") test, Transaction::Simple provides consistency and durability, but
#   cannot itself provide isolation. Transactions should be considered "critical
#   sections" in multi-threaded applications. Thread safety of the transaction
#   acquisition and release process itself can be ensured with the thread-safe
#   version, Transaction::Simple::ThreadSafe. With transaction groups, some
#   level of atomicity is assured.
# * does not maintain Object#__id__ values on rewind or abort. This only affects
#   complex self-referential graphs. tests/tc_broken_graph.rb demonstrates this
#   and its mitigation with the new post-rewind hook. #_post_transaction_rewind.
#   Matz has implemented an experimental feature in Ruby 1.9 that may find its
#   way into the released Ruby 1.9.1 and ultimately Ruby 2.0 that would obviate
#   the need for #_post_transaction_rewind. Pit Capitain has also suggested a
#   workaround that does not require changes to core Ruby, but does not work in
#   all cases. A final resolution is still pending further discussion.
# * Can be a memory hog if you use many levels of transactions on many
#   objects.
module Transaction::Simple
  TRANSACTION_SIMPLE_VERSION = '1.4.0'

  # Sets the Transaction::Simple debug object. It must respond to #<<.
  # Sets the transaction debug object. Debugging will be performed
  # automatically if there's a debug object. The generic transaction
  # error class.
  def self.debug_io=(io)
    if io.nil?
      @tdi        = nil
      @debugging  = false
    else
      raise Transaction::TransactionError, Transaction::Messages[:bad_debug_object] unless io.respond_to?(:<<)
      @tdi = io
      @debugging = true
    end
  end

  # Returns +true+ if we are debugging.
  def self.debugging?
    @debugging
  end

  # Returns the Transaction::Simple debug object. It must respond to
  # #<<.
  def self.debug_io
    @tdi ||= ""
    @tdi
  end

  # If +name+ is +nil+ (default), then returns +true+ if there is
  # currently a transaction open.
  #
  # If +name+ is specified, then returns +true+ if there is currently a
  # transaction that responds to +name+ open.
  def transaction_open?(name = nil)
    if name.nil?
      Transaction::Simple.debug_io << "Transaction " << "[#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" if Transaction::Simple.debugging?
      return (not @__transaction_checkpoint__.nil?)
    else
      Transaction::Simple.debug_io << "Transaction(#{name.inspect}) " << "[#{(@__transaction_checkpoint__.nil?) ? 'closed' : 'open'}]\n" if Transaction::Simple.debugging?
      return ((not @__transaction_checkpoint__.nil?) and @__transaction_names__.include?(name))
    end
  end

  # Returns the current name of the transaction. Transactions not
  # explicitly named are named +nil+.
  def transaction_name
    raise Transaction::TransactionError, Transaction::Messages[:no_transaction_open] if @__transaction_checkpoint__.nil?
    Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Transaction Name: #{@__transaction_names__[-1].inspect}\n" if Transaction::Simple.debugging?
    if @__transaction_names__[-1].kind_of?(String)
      @__transaction_names__[-1].dup
    else
      @__transaction_names__[-1]
    end
  end

  # Starts a transaction. Stores the current object state. If a
  # transaction name is specified, the transaction will be named.
  # Transaction names must be unique. Transaction names of +nil+ will be
  # treated as unnamed transactions.
  def start_transaction(name = nil)
    @__transaction_level__ ||= 0
    @__transaction_names__ ||= []

    name = name.dup.freeze if name.kind_of?(String)

    raise Transaction::TransactionError, Transaction::Messages[:unique_names] if name and @__transaction_names__.include?(name)

    @__transaction_names__ << name
    @__transaction_level__ += 1

    if Transaction::Simple.debugging?
      ss = "(#{name.inspect})"
      ss = "" unless ss

      Transaction::Simple.debug_io << "#{'>' * @__transaction_level__} " << "Start Transaction#{ss}\n"
    end

    @__transaction_checkpoint__ = Marshal.dump(self)
  end

  # Rewinds the transaction. If +name+ is specified, then the
  # intervening transactions will be aborted and the named transaction
  # will be rewound. Otherwise, only the current transaction is rewound.
  def rewind_transaction(name = nil)
    raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to rewind a transaction that is
    # outside of the current transaction block.
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_transaction_before_block] if nix < @__transaction_block__
    end

    if name.nil?
      __rewind_this_transaction
      ss = "" if Transaction::Simple.debugging?
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_rewind_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      ss = "(#{name})" if Transaction::Simple.debugging?

      while @__transaction_names__[-1] != name
        @__transaction_checkpoint__ = __rewind_this_transaction
        Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Rewind Transaction#{ss}\n" if Transaction::Simple.debugging?
        @__transaction_level__ -= 1
        @__transaction_names__.pop
      end
      __rewind_this_transaction
    end
    Transaction::Simple.debug_io << "#{'|' * @__transaction_level__} " << "Rewind Transaction#{ss}\n" if Transaction::Simple.debugging?
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
    raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to abort a transaction that is
    # outside of the current transaction block. Otherwise, raise
    # TransactionAborted if they are the same.
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_transaction_before_block] if nix < @__transaction_block__

      raise Transaction::TransactionAborted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionAborted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      __abort_transaction(name)
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_abort_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
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
    raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_no_transaction] if @__transaction_checkpoint__.nil?
    @__transaction_block__ ||= nil

    # Check to see if we are trying to commit a transaction that is
    # outside of the current transaction block. Otherwise, raise
    # TransactionCommitted if they are the same.
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_transaction_before_block] if nix < @__transaction_block__

      raise Transaction::TransactionCommitted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionCommitted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      ss = "" if Transaction::Simple.debugging?
      __commit_transaction
      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
    else
      raise Transaction::TransactionError, Transaction::Messages[:cannot_commit_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      ss = "(#{name})" if Transaction::Simple.debugging?

      while @__transaction_names__[-1] != name
        Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
        __commit_transaction
      end
      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Commit Transaction#{ss}\n" if Transaction::Simple.debugging?
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

  # Allows specific variables to be excluded from transaction support.
  # Must be done after extending the object but before starting the
  # first transaction on the object.
  #
  #   vv.transaction_exclusions << "@io"
  def transaction_exclusions
    @transaction_exclusions ||= []
  end

  class << self
    def __common_start(name, vars, &block)
      raise Transaction::TransactionError, Transaction::Messages[:cannot_start_empty_block_transaction] if vars.empty?

      if block
        begin
          vlevel = {}

          vars.each do |vv|
            vv.extend(Transaction::Simple)
            vv.start_transaction(name)
            vlevel[vv.__id__] = vv.instance_variable_get(:@__transaction_level__)
            vv.instance_variable_set(:@__transaction_block__, vlevel[vv.__id__])
          end

          yield(*vars)
        rescue Transaction::TransactionAborted
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
        rescue Transaction::TransactionCommitted
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

    if Transaction::Simple.debugging?
      if name.nil?
        ss = ""
      else
        ss = "(#{name.inspect})"
      end

      Transaction::Simple.debug_io << "#{'<' * @__transaction_level__} " << "Abort Transaction#{ss}\n"
    end

    @__transaction_level__ -= 1
    @__transaction_names__.pop
    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end

  SKIP_TRANSACTION_VARS = %w(@__transaction_checkpoint__ @__transaction_level__)

  def __rewind_this_transaction #:nodoc:
    rr = Marshal.restore(@__transaction_checkpoint__)

    begin
      self.replace(rr)
    rescue
      nil
    end

    iv = rr.instance_variables - SKIP_TRANSACTION_VARS - self.transaction_exclusions
    iv.each do |vv|
      next if self.transaction_exclusions.include?(vv)

      instance_variable_set(vv, rr.instance_variable_get(vv))
    end

    rest = instance_variables - rr.instance_variables - SKIP_TRANSACTION_VARS - self.transaction_exclusions
    rest.each do |vv|
      remove_instance_variable(vv)
    end

    _post_transaction_rewind if respond_to?(:_post_transaction_rewind)

    rr.instance_variable_get(:@__transaction_checkpoint__)
  end

  def __commit_transaction #:nodoc:
    old = Marshal.restore(@__transaction_checkpoint__)
    instance_variable_set(:@__transaction_checkpoint__,
                          old.instance_variable_get(:@__transaction_checkpoint__))

    @__transaction_level__ -= 1
    @__transaction_names__.pop

    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end

  private :__abort_transaction
  private :__rewind_this_transaction
  private :__commit_transaction
end
