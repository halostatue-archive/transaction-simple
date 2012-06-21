# -*- ruby encoding: utf-8 -*-

# :main: README.rdoc

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

  Messages = { #:nodoc:
    :bad_debug_object => te % "the transaction debug object must respond to #<<.",
    :unique_names => te % "named transactions must be unique.",
    :no_transaction_open => te % "no transaction open.",
    :cannot_rewind_no_transaction => te % "cannot rewind; there is no current transaction.",
    :cannot_rewind_named_transaction => te % "cannot rewind to transaction %s because it does not exist.",
    :cannot_rewind_transaction_before_block => te % "cannot rewind a transaction started before the execution block.",
    :cannot_abort_no_transaction => te % "cannot abort; there is no current transaction.",
    :cannot_abort_transaction_before_block => te % "cannot abort a transaction started before the execution block.",
    :cannot_abort_named_transaction => te % "cannot abort nonexistant transaction %s.",
    :cannot_commit_no_transaction => te % "cannot commit; there is no current transaction.",
    :cannot_commit_transaction_before_block => te % "cannot commit a transaction started before the execution block.",
    :cannot_commit_named_transaction => te % "cannot commit nonexistant transaction %s.",
    :cannot_start_empty_block_transaction => te % "cannot start a block transaction with no objects.",
    :cannot_obtain_transaction_lock => te % "cannot obtain transaction lock for #%s.",
    :transaction => "Transaction",
    :opened => "open",
    :closed => "closed",
    :transaction_name => "Transaction Name",
    :start_transaction => "Start Transaction",
    :rewind_transaction => "Rewind Transaction",
    :commit_transaction => "Commit Transaction",
    :abort_transaction => "Abort Transaction",
  }
end

module Transaction::Simple
  VERSION = TRANSACTION_SIMPLE_VERSION = '1.4.0.2'

  class << self
    # Sets the Transaction::Simple debug object. It must respond to #<<.
    # Debugging will be performed automatically if there's a debug object.
    def debug_io=(io)
      if io.nil?
        @tdi        = nil
        @debugging  = false
      else
        raise Transaction::TransactionError, Transaction::Messages[:bad_debug_object] unless io.respond_to?(:<<)
        @tdi = io
        @debugging = true
      end
    end

    # Set to +true+ if you want the checkpoint printed with debugging
    # messages where it matters.
    attr_accessor :debug_with_checkpoint

    # Returns +true+ if we are debugging.
    def debugging?
      defined? @debugging and @debugging
    end

    # Returns the Transaction::Simple debug object. It must respond to #<<.
    def debug_io
      @tdi ||= ""
      @tdi
    end

    # Fast debugging.
    def debug(format, *args)
      return unless debugging?
      debug_io << (format % args)
    end
  end

  def ___tmessage
    Transaction::Messages
  end
  private :___tmessage

  def ___tdebug(char, format, *args)
    return unless Transaction::Simple.debugging?
    if @__transaction_level__ > 0
      Transaction::Simple.debug "#{char * @__transaction_level__} #{format}", args
    else
      Transaction::Simple.debug "#{format}", args
    end
  end
  private :___tdebug

  def ___tdebug_checkpoint
    return unless Transaction::Simple.debugging?
    return unless Transaction::Simple.debug_with_checkpoint

    ___tdebug '|', '%s', @__transaction_checkpoint__.inspect
  end
  private :___tdebug_checkpoint

  # If +name+ is +nil+ (default), then returns +true+ if there is currently
  # a transaction open. If +name+ is specified, then returns +true+ if there
  # is currently a transaction known as +name+ open.
  def transaction_open?(name = nil)
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil

    has_t = nil

    if name.nil?
      has_t = (not @__transaction_checkpoint__.nil?)
    else
      has_t = ((not @__transaction_checkpoint__.nil?) and
               @__transaction_names__.include?(name))
    end

    ___tdebug '>', "%s [%s]", ___tmessage[:transaction], ___tmessage[has_t ? :opened : :closed]

    has_t
  end

  # Returns the current name of the transaction. Transactions not explicitly
  # named are named +nil+.
  def transaction_name
    raise Transaction::TransactionError, ___tmessage[:no_transaction_open] if @__transaction_checkpoint__.nil?

    name = @__transaction_names__.last

    ___tdebug '|', "%s(%s)", ___tmessage[:transaction_name], name.inspect

    if name.kind_of?(String)
      name.dup
    else
      name
    end
  end

  # Starts a transaction. Stores the current object state. If a transaction
  # name is specified, the transaction will be named. Transaction names must
  # be unique. Transaction names of +nil+ will be treated as unnamed
  # transactions.
  def start_transaction(name = nil)
    @__transaction_level__ ||= 0
    @__transaction_names__ ||= []

    name = name.dup.freeze if name.kind_of?(String)

    raise Transaction::TransactionError, ___tmessage[:unique_names] if name and @__transaction_names__.include?(name)

    @__transaction_names__ << name
    @__transaction_level__ += 1

    ___tdebug '>', "%s(%s)", ___tmessage[:start_transaction], name.inspect
    ___tdebug_checkpoint

    checkpoint = Marshal.dump(self)

    @__transaction_checkpoint__ = Marshal.dump(self)
  end

  # Rewinds the transaction. If +name+ is specified, then the intervening
  # transactions will be aborted and the named transaction will be rewound.
  # Otherwise, only the current transaction is rewound.
  #
  # After each level of transaction is rewound, if the callback method
  # #_post_transaction_rewind is defined, it will be called. It is intended
  # to allow a complex self-referential graph to fix itself. The simplest
  # way to explain this is with an example.
  #
  #   class Child
  #     attr_accessor :parent
  #   end
  #
  #   class Parent
  #     include Transaction::Simple
  #
  #     attr_reader :children
  #     def initialize
  #       @children = []
  #     end
  #
  #     def << child
  #       child.parent = self
  #       @children << child
  #     end
  #
  #     def valid?
  #       @children.all? { |child| child.parent == self }
  #     end
  #   end
  #
  #   parent = Parent.new
  #   parent << Child.new
  #   parent.start_transaction
  #   parent << Child.new
  #   parent.abort_transaction
  #   puts parent.valid? # => false
  #
  # This problem can be fixed by modifying the Parent class to include the
  # #_post_transaction_rewind callback.
  #
  #   class Parent
  #     # Reconnect the restored children to me, instead of to the bogus me
  #     # that was restored to them by Marshal::load.
  #     def _post_transaction_rewind
  #       @children.each { |child| child.parent = self }
  #     end
  #   end
  #
  #   parent = Parent.new
  #   parent << Child.new
  #   parent.start_transaction
  #   parent << Child.new
  #   parent.abort_transaction
  #   puts parent.valid? # => true
  def rewind_transaction(name = nil)
    raise Transaction::TransactionError, ___tmessage[:cannot_rewind_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to rewind a transaction that is outside
    # of the current transaction block.
    defined? @__transaction_block__ or @__transaction_block__ = nil
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, ___tmessage[:cannot_rewind_transaction_before_block] if nix < @__transaction_block__
    end

    if name.nil?
      checkpoint = @__transaction_checkpoint__
      __rewind_this_transaction
      @__transaction_checkpoint__ = checkpoint
    else
      raise Transaction::TransactionError, ___tmessage[:cannot_rewind_named_transaction] % name.inspect unless @__transaction_names__.include?(name)

      while @__transaction_names__.last != name
        ___tdebug_checkpoint
        @__transaction_checkpoint__ = __rewind_this_transaction
        ___tdebug '<', ___tmessage[:rewind_transaction], name
        @__transaction_level__ -= 1
        @__transaction_names__.pop
      end

      checkpoint = @__transaction_checkpoint__
      __rewind_this_transaction
      @__transaction_checkpoint__ = checkpoint
    end

    ___tdebug '|', "%s(%s)", ___tmessage[:rewind_transaction], name.inspect
    ___tdebug_checkpoint

    self
  end

  # Aborts the transaction. Rewinds the object state to what it was before
  # the transaction was started and closes the transaction. If +name+ is
  # specified, then the intervening transactions and the named transaction
  # will be aborted. Otherwise, only the current transaction is aborted.
  #
  # See #rewind_transaction for information about dealing with complex
  # self-referential object graphs.
  #
  # If the current or named transaction has been started by a block
  # (Transaction::Simple.start), then the execution of the block will be
  # halted with +break+ +self+.
  def abort_transaction(name = nil)
    raise Transaction::TransactionError, ___tmessage[:cannot_abort_no_transaction] if @__transaction_checkpoint__.nil?

    # Check to see if we are trying to abort a transaction that is outside
    # of the current transaction block. Otherwise, raise TransactionAborted
    # if they are the same.
    defined? @__transaction_block__ or @__transaction_block__ = nil
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, ___tmessage[:cannot_abort_transaction_before_block] if nix < @__transaction_block__
      raise Transaction::TransactionAborted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionAborted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      __abort_transaction(name)
    else
      raise Transaction::TransactionError, ___tmessage[:cannot_abort_named_transaction] % name.inspect unless @__transaction_names__.include?(name)
      __abort_transaction(name) while @__transaction_names__.include?(name)
    end

    self
  end

  # If +name+ is +nil+ (default), the current transaction level is closed
  # out and the changes are committed.
  #
  # If +name+ is specified and +name+ is in the list of named transactions,
  # then all transactions are closed and committed until the named
  # transaction is reached.
  def commit_transaction(name = nil)
    raise Transaction::TransactionError, ___tmessage[:cannot_commit_no_transaction] if @__transaction_checkpoint__.nil?
    @__transaction_block__ ||= nil

    # Check to see if we are trying to commit a transaction that is outside
    # of the current transaction block. Otherwise, raise
    # TransactionCommitted if they are the same.
    if @__transaction_block__ and name
      nix = @__transaction_names__.index(name) + 1
      raise Transaction::TransactionError, ___tmessage[:cannot_commit_transaction_before_block] if nix < @__transaction_block__

      raise Transaction::TransactionCommitted if @__transaction_block__ == nix
    end

    raise Transaction::TransactionCommitted if @__transaction_block__ == @__transaction_level__

    if name.nil?
      ___tdebug "<", "%s(%s)", ___tmessage[:commit_transaction], name.inspect
      __commit_transaction
    else
      raise Transaction::TransactionError, ___tmessage[:cannot_commit_named_transaction] % name.inspect unless @__transaction_names__.include?(name)

      while @__transaction_names__.last != name
        ___tdebug "<", "%s(%s)", ___tmessage[:commit_transaction], name.inspect
        __commit_transaction
        ___tdebug_checkpoint
      end

      ___tdebug "<", "%s(%s)", ___tmessage[:commit_transaction], name.inspect
      __commit_transaction
    end

    ___tdebug_checkpoint

    self
  end

  # Alternative method for calling the transaction methods. An optional name
  # can be specified for named transaction support. This method is
  # deprecated and will be removed in Transaction::Simple 2.0.
  #
  # #transaction(:start)::  #start_transaction
  # #transaction(:rewind):: #rewind_transaction
  # #transaction(:abort)::  #abort_transaction
  # #transaction(:commit):: #commit_transaction
  # #transaction(:name)::   #transaction_name
  # #transaction::          #transaction_open?
  def transaction(action = nil, name = nil)
    _method = case action
              when :start then :start_transaction
              when :rewind then :rewind_transaction
              when :abort then :abort_transaction
              when :commit then :commit_transaction
              when :name then :transaction_name
              when nil then :transaction_open?
              else nil
              end

    if _method
      warn "The #transaction method has been deprecated. Use #{_method} instead."
    else
      warn "The #transaction method has been deprecated."
    end

    case _method
    when :transaction_name
      __send__ _method
    when nil
      nil
    else
      __send__ _method, name
    end
  end

  # Allows specific variables to be excluded from transaction support. Must
  # be done after extending the object but before starting the first
  # transaction on the object.
  #
  #   vv.transaction_exclusions << "@io"
  def transaction_exclusions
    @transaction_exclusions ||= []
  end

  class << self
    def __common_start(name, vars, &block)
      raise Transaction::TransactionError, ___tmessage[:cannot_start_empty_block_transaction] if vars.empty?

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

    # Start a named transaction in a block. The transaction will auto-commit
    # when the block finishes.
    def start_named(name, *vars, &block)
      __common_start(name, vars, &block)
    end

    # Start a named transaction in a block. The transaction will auto-commit
    # when the block finishes.
    def start(*vars, &block)
      __common_start(nil, vars, &block)
    end
  end

  def __abort_transaction(name = nil) #:nodoc:
    @__transaction_checkpoint__ = __rewind_this_transaction

    ___tdebug '<', "%s(%s)", ___tmessage[:abort_transaction], name.inspect
    ___tdebug_checkpoint

    @__transaction_level__ -= 1
    @__transaction_names__.pop

    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end
  private :__abort_transaction

  SKIP_TRANSACTION_VARS = %w(@__transaction_checkpoint__ @__transaction_level__)

  def __rewind_this_transaction #:nodoc:
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil
    raise Transaction::TransactionError, ___tmessage[:cannot_rewind_no_transaction] if @__transaction_checkpoint__.nil?
    rr = Marshal.restore(@__transaction_checkpoint__)

    replace(rr) if respond_to?(:replace)

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

    w, $-w = $-w, false # 20070203 OH is this very UGLY
    res = rr.instance_variable_get(:@__transaction_checkpoint__)
    $-w = w # 20070203 OH is this very UGLY
    res
  end
  private :__rewind_this_transaction

  def __commit_transaction #:nodoc:
    defined? @__transaction_checkpoint__ or @__transaction_checkpoint__ = nil
    raise Transaction::TransactionError, ___tmessage[:cannot_commit_no_transaction] if @__transaction_checkpoint__.nil?
    old = Marshal.restore(@__transaction_checkpoint__)
    w, $-w = $-w, false # 20070203 OH is this very UGLY
    @__transaction_checkpoint__ = old.instance_variable_get(:@__transaction_checkpoint__)
    $-w = w # 20070203 OH is this very UGLY

    @__transaction_level__ -= 1
    @__transaction_names__.pop

    if @__transaction_level__ < 1
      @__transaction_level__ = 0
      @__transaction_names__ = []
      @__transaction_checkpoint__ = nil
    end
  end
  private :__commit_transaction
end

# vim: syntax=ruby
