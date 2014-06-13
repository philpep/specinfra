require 'specinfra/backend/exec'
require 'open3'
require 'base64'

module SpecInfra
  module Backend
    class OpenSSH < Exec
      def run_command(cmd, opt={})
        cmd = build_command(cmd)
        cmd = add_pre_command(cmd)
        ret = ssh_exec!(cmd)

        ret[:stdout].gsub!(/\r\n/, "\n")

        if @example
          @example.metadata[:command] = cmd
          @example.metadata[:stdout]  = ret[:stdout]
        end

        CommandResult.new ret
      end

      def copy_file(from, to)
        raise NotImplementedError
      end

      private
      def ssh_exec!(command)
        command = Base64.strict_encode64(command).chomp
        host = SpecInfra.configuration.openssh[:host]
        port = SpecInfra.configuration.openssh[:port]
        cmd = "ssh -q root@#{host} -p #{port} 'eval $(echo #{command} | base64 -d)'"
        _, stdout, stderr, wait_thr = Open3.popen3(cmd)
        {
            :stdout => stdout.read,
            :stderr => stderr.read,
            :exit_status => wait_thr.value.to_i,
            :exit_signal => nil,
        }
      end
    end
  end
end
