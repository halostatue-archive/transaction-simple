$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'uninheritable'
require 'test/unit'

class TC_Uninheritable < Test::Unit::TestCase #:nodoc:
  class Cannot #:nodoc:
    extend Uninheritable
  end
  class Can #:nodoc:
  end

  def test_module #:nodoc:
    assert_nothing_raised {
      self.instance_eval <<-EOS
      class A < Can; end
      EOS
    }
    assert_raises(TypeError, "Class Cannot cannot be subclassed.") do
      self.instance_eval <<-EOS
      class B < Cannot; end
      EOS
    end
  end
end
