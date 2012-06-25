# Patches to Resque
# I should be needed if we are using the taskrabbit patch to resque...

# This module overrides Resque's default implementation of worker_pids based on Linux "ps" output
# to be compatible with most Solaris-based platforms.
#
# See https://github.com/defunkt/resque/issues/339
# for more information
# module Resque
#   class Worker
#     def worker_pids
#       if RUBY_PLATFORM =~ /solaris/
#         `ps -A -o pid,comm | grep ruby | grep -v grep | grep -v "resque-web"`.split("\n").map do |line|
#           real_pid = line.split(' ')[0]
#           pargs_command = `pargs -a #{real_pid} 2>/dev/null | grep [r]esque | grep -v "resque-web"`
#           nombre = pargs_command.split(':')[1]
#           nombre = nombre.split(" ").last unless nombre.nil?
#           if nombre == "resquebus"
#             real_pid
#           end
#         end.reject(&:nil?)
#       else
#         `ps -A -o pid,command | grep [r]esque | grep -v "resque-web"`.split("\n").map do |line|
#           line.split(' ')[0]
#         end
#       end
#     end
#   end
# end