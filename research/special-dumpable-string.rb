load 'special-dumpable.rb'

class Child
  attr_accessor :parent
end

class Parent < String
  include SpecialDumpable

  attr_reader :children
  def initialize(value)
    super
    @children = []
  end

  def << child
    child.parent = self
    @children << child
  end
end

parent = Parent.new("gold")
puts "parent(#{parent}).object_id: #{parent.object_id}"
parent << Child.new
puts "parent(#{parent}).children[0].parent.object_id: #{parent.children[0].parent.object_id}"
puts "starting transaction with childcount #{parent.children.size}"
s = parent.special_dump
parent << Child.new
parent.gsub!(/gold/, 'pyrite')
puts "parent(#{parent}).children[1].parent.object_id: #{parent.children[1].parent.object_id}"
puts "aborting transaction with childcount #{parent.children.size}"
parent.special_restore s
puts "parent(#{parent})"
puts "aborted transaction with childcount #{parent.children.size}"
puts "parent.object_id: #{parent.object_id}"
puts "parent.children[0].parent.object_id: #{parent.children[0].parent.object_id}"
parent << Child.new
puts "parent.children[1].parent.object_id: #{parent.children[1].parent.object_id}"
