require 'transaction/simple/threadsafe'

  # A transaction group is an object wrapper that manages a group of objects
  # as if they were a single object for the purpose of transaction
  # management. All transactions for this group of objects should be
  # performed against the transaction group object, not against individual
  # objects in the group. This is the threadsafe version of a transaction
  # group.
class Transaction::Simple::ThreadSafe::Group < Transaction::Simple::Group
  def initialize(*objects)
    @objects = objects || []
    @objects.freeze
    @objects.each { |obj| obj.extend(Transaction::Simple::ThreadSafe) }

    if block_given?
      begin
        yield self
      ensure
        self.clear
      end
    end
  end
end
