require 'fileutils'
require 'puppet/util/execution'
require 'shellwords'

Puppet::Type.type(:repository).provide :git do
  include Puppet::Util::Execution

  optional_commands :git => 'git'

  def self.default_protocol
    'https'
  end

  def exists?
    File.directory?(@resource[:path]) &&
      File.directory?("#{@resource[:path]}/.git")
  end

  def create
    command = [
      command(:git),
      "clone",
      friendly_extra,
      friendly_source,
      friendly_path
    ].flatten.compact

    execute command, command_opts
  end

  def destroy
    FileUtils.rm_rf @resource[:path]
  end

  def expand_source(source)
    if source =~ /\A[^@\/\s]+\/[^\/\s]+\z/
      "#{@resource[:protocol]}://github.com/#{source}"
    else
      source
    end
  end

  def command_opts
    @command_opts ||= build_command_opts
  end

  def build_command_opts
    default_commands_opts.tap do |h|
      if uid = (self[:user] || self.class.default_user)
        h[:uid] = uid
      end
    end
  end

  def default_command_opts
    {
      :combine    => true,
      :failonfail => true
    }
  end

  def friendly_extra
    @friendly_extra ||= [@resource[:extra]].flatten.map do |o|
      Shellwords.escape(o)
    end.join(' ').strip
  end

  def friendly_source
    @friendly_source ||= Shellwords.escape(expand_source(@resource[:source]))
  end

  def friendly_path
    @friendly_path ||= Shellwords.escape(@resource[:path])
  end
end
