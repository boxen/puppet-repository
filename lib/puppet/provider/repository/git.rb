require 'fileutils'

Puppet::Type.type(:repository).provide(:git) do
  desc "Git repository clones"

  def autorequire
    ['git']
  end

  def self.git_bin
    if boxen_home = Facter[:boxen_home].value
      "#{boxen_home}/homebrew/bin/git"
    else
      `which git`.strip
    end
  end

  def self.default_protocol
    'https'
  end

  def exists?
    File.directory?(@resource[:path]) &&
      File.directory?("#{@resource[:path]}/.git")
  end

  def create
    source = expand_source(@resource[:source])
    path = @resource[:path]

    options = {
      :combine    => true,
      :failonfail => true,
    }

    if boxen_user = Facter[:boxen_user].value
      options[:uid] = boxen_user
    end

    execute [
      self.class.git_bin,
      "clone",
      @resource[:extra].to_a.flatten.join(' ').strip,
      source,
      path
    ].join(' '), options
    end

  def destroy
    path = @resource[:path]

    FileUtils.rm_rf path
  end

  def expand_source(source)
    if source =~ /\A\S+\/\S+\z/
      "#{@resource[:protocol]}://github.com/#{source}"
    else
      source
    end
  end
end
