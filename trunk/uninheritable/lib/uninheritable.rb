#:title: Module Uninheritable
#:main: Uninheritable
#--
# Uninheritable
# Version 1.0.1.0
#
# Copyright (c) 2003 Austin Ziegler
#
# $Id$
#
# ==========================================================================
# Revision History ::
# YYYY.MM.DD  Developer       Description
# --------------------------------------------------------------------------
# 2003.09.17  Austin Ziegler  Minor modifications to documentation.
# ==========================================================================
#++

# = Introduction
#
# Allows an object to declare itself as unable to be subclassed. The
# technique behind this is very simple (redefinition of #inherited), so this
# just provides an easier way to do the same thing with a consistent error
# message.
#
# == Usage
#
#   require 'uninheritable'
#
#   class A
#     extend Uninheritable
#   end
#
#   class B < A; end # => raises TypeError
#
# == Info
# Copyright:: Copyright (c) 2003 Austin Ziegler
# Licence::   MIT-Style
# Version::   1.0
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
module Uninheritable
  UNINHERITABLE_VERSION = "1.0.1.0"
    # Redefines a class's #inherited definition to prevent subclassing of the
    # class extended by this module.
  def inherited(klass)
    raise TypeError, "Class #{self} cannot be subclassed."
  end
end

if $0 == __FILE__
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
end
