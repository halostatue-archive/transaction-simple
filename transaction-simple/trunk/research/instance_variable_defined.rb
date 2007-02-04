You can use this code for previous versions.

 unless defined?(instance_variable_defined?)
   module Kernel
     (t = Object.new).instance_eval {@instance_variable = 1}
     case t.instance_variables[0]
     when Symbol
       def instance_variable_defined?(var)
       instance_variables.include?(var.to_sym)
       end
     when String
       def instance_variable_defined?(var)
       instance_variables.include?(var.to_s)
       end
     end
   end
 end
