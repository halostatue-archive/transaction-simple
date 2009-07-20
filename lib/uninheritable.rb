#:title: Uninheritable
#:main: Uninheritable
#--
# Uninheritable
# Version 1.0.2
#
# Copyright (c) 2003 - 2005 Austin Ziegler
#
# $Id$
#++

  # = Introduction
  #
  # Allows an object to declare itself as unable to be subclassed. The
  # technique behind this is very simple (redefinition of #inherited), so
  # this just provides an easier way to do the same thing with a consistent
  # error message.
  #
  # == Usage
  #   require 'uninheritable'
  #
  #   class A
  #     extend Uninheritable
  #   end
  #
  #   class B < A; end # => raises TypeError
  #
  # == Info
  # Copyright:: Copyright (c) 2003 - 2005 Austin Ziegler
  # Licence::   MIT-Style
  # Version::   1.0.2
  #
  # == Licence
  # Permission is hereby granted, free of charge, to any person obtaining a
  # copy of this software and associated documentation files (the
  # "Software"), to deal in the Software without restriction, including
  # without limitation the rights to use, copy, modify, merge, publish,
  # distribute, sublicense, and/or sell copies of the Software, and to
  # permit persons to whom the Software is furnished to do so, subject to
  # the following conditions:
  #
  # The above copyright notice and this permission notice shall be included
  # in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  # OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  # IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  # CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  # TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  # SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module Uninheritable
  UNINHERITABLE_VERSION = "1.0.2"
    # Redefines a class's #inherited definition to prevent subclassing of the
    # class extended by this module.
  def inherited(klass)
    raise TypeError, "Class #{self} cannot be subclassed."
  end
end
