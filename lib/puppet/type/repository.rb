require 'pathname'

Puppet.newtype :repository do

  ensurable do
    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end

    newvalue /./ do
      provider.ensure_remote
      provider.ensure_revision
    end

    defaultto :present


    def retrieve
      provider.query[:ensure]
    end

    def insync?(is)
      @should.each { |should|
        case should
        when :present
          return true unless is == :absent
        when :absent
          return true if is == :absent
        when *Array(is)
          return true
        end
      }
      false
    end
  end

  newparam :path, :namevar => true do
    desc "The path of the repository."

    validate do |value|
      unless Pathname.new(value).absolute?
        raise Puppet::Error, \
          "Path must be absolute for Repository[#{value}]"
      end
    end
  end

  newparam :source do
    desc "The remote source for the repository."
  end

  newparam :protocol do
    desc "The protocol used to fetch the repository."

    defaultto do
      if provider.class.respond_to? :default_protocol
        provider.class.default_protocol
      end
    end

    validate do |v|
      provider.class.validate v
    end
  end

  newparam :user do
    desc "User to run this operation as."

    defaultto do
      Facter.value(:boxen_user) || Facter.value(:id) || "root"
    end
  end

  newparam :config do
    desc "The config to pass to the running provider"

    validate do |value|
      unless value.is_a? Hash
        raise Puppet::Error, "Repository#config must be a Hash"
      end
    end
  end

  newparam :extra, :array_matching => :all do
    desc "Extra actions or information for a provider"
  end

  newparam :force do
    desc "Whether or not to force reset if the working tree is dirty"

    validate do |value|
      unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        raise Puppet::Error, \
          "Force must be true or false"
      end
    end

    defaultto false
  end

  validate do
    if self[:source].nil?
      # ensure => absent does not need a source
      unless self[:ensure] == :absent || self[:ensure] == 'absent'
        raise Puppet::Error, \
          "You must specify a source for Repository[#{self[:name]}]"
      end
    end
  end

  def exists?
    @provider.query[:ensure] != @parameters[:ensure]
  end

  autorequire :file do
    Array.new.tap do |a|
      path = Pathname.new self[:path]

      unless path.root?
        tree_walker = path.parent.enum_for :ascend

        tree_walker.each do |dir|
          a << dir.to_s if catalog.resource(:file, dir.to_s)
        end
      end
    end
  end

  autorequire :user do
    Array.new.tap do |a|
      if @parameters.include?(:user) && user = @parameters[:user].to_s
        a << user if catalog.resource(:user, user)
      end
    end
  end
end
