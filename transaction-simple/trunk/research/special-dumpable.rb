#!/usr/bin/env ruby
#
#  SpecialDumpable  -  workaround for a problem in Transaction::Simple
#
#  (C) 2006 Pit Capitain
#
#  For a description of the problem see http://www.halostatue.ca/2006/10/22/
#    ruby-conference-2006-day-1-evening-friday-20-october-2006/
#  and http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/155092
#
#  The workaround:
#
#  The objects that are restored from Marshal shouldn't reference the newly
#  created root object, but the original root object. After studying the
#  source code of Marshal, I found that this could be achieved with a special
#  _load method of the root object's class which returns the original root
#  object. Then the original root object would be stored in the internal list
#  of restored objects and references to the root object would use the original
#  one.
#
#  See SpecialDumpable::ClassMethods#_load
#
#  In order to get at the original root object from a class method, we store
#  its object_id in the Marshal string.
#
#  See SpecialDumpable#_dump
#
#  Note: this means that classes with their own _load and _dump methods cannot
#  be used with this implementation. I think it should be possible to enhance
#  the implementation to support these classes, too.
#
#  Using those two methods, the objects restored from Marshal really reference
#  the original root object. But this is not enough. We have to restore the
#  instance variables of the root object, too. The _dump method from above
#  only dumps the object_id of the root object, not its instance variables.
#
#  For the instance variables, we create a new object and store the instance
#  variables of the root object there. Then we not only serialize the root
#  object, but an array with both the root object and the object with the
#  instance variables.
#
#  See SpecialDumpable#special_dump
#
#  The root object dumps its object_id, and the object with the instance
#  variables dumps the instance variables of the root object.
#
#  When restoring the objects, Marshal creates an array with the root object
#  plus an object with the restored instance variables of the root object.
#  We only need to replace the current instance variables of the root object
#  with the restored instance variables to get the desired behaviour.
#
#  See SpecialDumpable#special_restore
#
#  That's it.


module SpecialDumpable
  
  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods
    def _load source
      ObjectSpace._id2ref source.to_i
    end
  end

  def _dump limit
    object_id.to_s
  end
  
  def special_dump
    value_holder = Object.new
    SpecialDumpable.copy_instance_variables self, value_holder
    Marshal.dump [ self, value_holder ]
  end
  
  def special_restore source  
    self_that_can_be_ignored, value_holder = Marshal.restore source
    SpecialDumpable.copy_instance_variables value_holder, self
    self
  end

  def self.copy_instance_variables from, to
    from.instance_variables.each do |var|
      val = from.instance_variable_get var
      to.instance_variable_set var, val
    end
  end
  
end

if __FILE__ == $0
  class Child
    attr_accessor :parent
  end

  class Parent
    include SpecialDumpable

    attr_reader :children
    def initialize
      @children = []
    end

    def << child
      child.parent = self
      @children << child
    end
  end

  parent = Parent.new
  puts "parent.object_id: #{parent.object_id}"
  parent << Child.new
  puts "parent.children[0].parent.object_id: #{parent.children[0].parent.object_id}"
  puts "starting transaction with childcount #{parent.children.size}"
  s = parent.special_dump
  parent << Child.new
  puts "parent.children[1].parent.object_id: #{parent.children[1].parent.object_id}"
  puts "aborting transaction with childcount #{parent.children.size}"
  parent.special_restore s
  puts "aborted transaction with childcount #{parent.children.size}"
  puts "parent.object_id: #{parent.object_id}"
  puts "parent.children[0].parent.object_id: #{parent.children[0].parent.object_id}"
  parent << Child.new
  puts "parent.children[1].parent.object_id: #{parent.children[1].parent.object_id}"
end