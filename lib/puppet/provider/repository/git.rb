require 'fileutils'
require 'puppet/util/errors'
require 'puppet/util/execution'
require 'shellwords'

Puppet::Type.type(:repository).provide :git do
  include Puppet::Util::Execution
  include Puppet::Util::Errors

  optional_commands :git => 'git'

  def self.default_protocol
    'https'
  end

  def self.validate(v)
    unless %w(git ssh https).member? v.to_s
      raise Puppet::Error, \
        "Protocol can only be git, https, or ssh for now!"
    end
  end

  def query
    h = { :name => @resource[:name], :provider => :git }

    if cloned?
      if @resource[:ensure] == :absent
          h.merge(:ensure => :present)
      elsif @resource[:ensure] == :present
        if correct_remote?
          h.merge(:ensure => :present)
        else
          # we need to ensure the correct remote, cheat #exists?
          h.merge(:ensure => :update)
        end
      else
        if correct_remote? && correct_revision?
          h.merge(:ensure => @resource[:ensure])
        else
          # we need to ensure the correct revision and remote, cheat #exists?
          h.merge(:ensure => :update)
        end
      end
    else
      h.merge(:ensure => :absent)
    end
  end

  def create
    command = [
      command(:git),
      "clone",
      friendly_config,
      friendly_extra,
      friendly_source,
      friendly_path
    ].flatten.compact.join(' ')

    execute command, command_opts
  end

  def ensure_remote
    create unless cloned?

    unless correct_remote?
      Dir.chdir @resource[:path] do
        execute [command(:git), "config", "remote.origin.url", friendly_source], command_opts

        Puppet.notice("Repository[#{@resource[:name]}] changing source from #{current_remote} to #{friendly_source}")
      end
    end
  end

  def ensure_revision
    create unless cloned?

    Dir.chdir @resource[:path] do
      status = execute [command(:git), "status", "--porcelain"], command_opts

      if status.empty?
        execute [command(:git), "reset", "--hard", target_revision], command_opts
      else
        if @resource[:force]
          Puppet.warning("Repository[#{@resource[:name]}] tree is dirty and force is true: doing hard reset!")
          execute [command(:git), "reset", "--hard", target_revision], command_opts
        else
          fail("Repository[#{@resource[:name]}] tree is dirty and force is false: cannot sync resource!")
        end
      end
    end
  end

  def destroy
    FileUtils.rm_rf @resource[:path]
  end

  def expand_source(source)
    if source =~ /\A[^@\/\s]+\/[^\/\s]+\z/
      case @resource[:protocol]
      when "git", "https"
        "#{@resource[:protocol]}://github.com/#{source}"
      when "ssh"
        "git@github.com:#{source}.git"
      else
        raise "failtown"
      end
    else
      source
    end
  end

  def command_opts
    @command_opts ||= build_command_opts
  end

  def build_command_opts
    default_command_opts.tap do |h|
      if uid = (@resource[:user] || self.class.default_user)
        h[:uid] = uid
      end
    end
  end

  def default_command_opts
    {
      :combine     => true,
      :failonfail  => true
    }
  end

  def friendly_config
    return if @resource[:config].nil?
    @friendly_config ||= Array.new.tap do |a|
      @resource[:config].each do |setting, value|
        a << "-c #{setting}=#{value}"
      end
    end.join(' ').strip
  end

  def friendly_extra
    @friendly_extra ||= [@resource[:extra]].flatten.join(' ').strip
  end

  def friendly_source
    @friendly_source ||= expand_source(@resource[:source])
  end

  def friendly_path
    @friendly_path ||= Shellwords.escape(@resource[:path])
  end

  private

  def current_revision
    @current_revision ||= Dir.chdir @resource[:path] do
      execute([
        command(:git), "rev-parse", "HEAD"
      ], command_opts).chomp
    end
  end

  def target_revision
    @target_revision ||= Dir.chdir @resource[:path] do
      execute([
        command(:git), "rev-list", "--max-count=1", @resource[:ensure]
      ], command_opts).chomp
    end
  end

  def current_remote
    @current_remote ||= Dir.chdir @resource[:path] do
      execute([
        command(:git), "config", "--get", "remote.origin.url"
      ], command_opts).chomp
    end
  end

  def cloned?
    File.directory?(@resource[:path]) &&
      File.directory?("#{@resource[:path]}/.git")
  end

  def correct_revision?
    Dir.chdir @resource[:path] do
      execute [
        command(:git), "fetch", "-q", "origin"
      ], command_opts

      current_revision == target_revision
    end
  end

  def correct_remote?
    current_remote == friendly_source
  end
end
