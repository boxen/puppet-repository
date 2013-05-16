require 'fileutils'
require 'puppet/util/execution'
require 'shellwords'

Puppet::Type.type(:repository).provide :git do
  include Puppet::Util::Execution

  optional_commands :git => 'git'

  def self.default_protocol
    'https'
  end

  def query
    h = { :name => @resource[:name], :provider => :git }

    if cloned?
      if [:present, :absent).member? @resource[:ensure]
        Puppet.warning("Repository[#{@resource[:name]}] ensure => #{@resource[:ensure]}")
        h.merge(:ensure => (cloned? ? :present : :absent))
      else
        if correct_revision?
          h.merge(:ensure => @resource[:ensure])
        else
          h.merge(:ensure => current_revision)
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

  def ensure_revision
    create unless cloned?

    Dir.chdir @resource[:path] do
      execute [command(:git), "reset", "--hard", target_revision], command_opts
    end
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
end
