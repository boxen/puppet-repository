require 'pathname'

Puppet.newtype :repository do

  ensurable do
    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end

    defaultto :present
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
  end

  newparam :user do
    desc "User to run this operation as."

    defaultto do
      if provider.class.respond_to? :default_user
        provider.class.default_user
      end
    end
  end

  newparam :extra, :array_matching => :all do
    desc "Extra actions or information for a provider"
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

  autorequire :file do
    Array.new.tap do |a|
      tree, _, leaf = path.rpartition('/')

      path_builder = ""

      tree.split('/').each do |node|
        a << (path_builder << "/#{node}").dup unless node.empty?
      end
    end
  end

  autorequire :user do
    Array.new.tap do |a|
      a << self[:user] unless self[:user].nil?
    end
  end
end
