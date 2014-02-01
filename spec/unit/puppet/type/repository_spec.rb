require 'spec_helper'

describe Puppet::Type.type(:repository) do
  let(:default_opts) do
    {
      :source => 'boxen/boxen',
      :path => '/tmp/boxen',
    }
  end

  let(:factory) do
    lambda { |opts|
      described_class.new opts
    }
  end

  let(:resource) {
    described_class.new default_opts
  }

  context "ensure" do
    it "should default to present" do
      resource[:ensure].should == :present
    end

    it "should accept a value of present or absent" do
      resource[:ensure] = :present
      resource[:ensure].should == :present

      resource[:ensure] = :absent
      resource[:ensure].should == :absent
    end
  end

  context "path" do
    it "should accept an absolute path as a value" do
      expect {
        resource[:path] = '/tmp/foo'
      }.to_not raise_error
    end

    it "should not accept a relative path as a value" do
      expect {
        resource[:path] = 'foo'
      }.to raise_error(Puppet::Error, /Path must be absolute for Repository\[foo\]/)
    end

    it "should fail when not provided with a value" do
      expect {
        factory.call :source => 'boxen/boxen'
      }.to raise_error(Puppet::Error, /Title or name must be provided/)
    end
  end

  context "source" do
    it "should accept any value" do
      resource[:source] = 'boxen/test'
      resource[:source].should == 'boxen/test'
    end

    it "should fail when not provided with a value" do
      expect {
        factory.call :path => '/tmp/foo'
      }.to raise_error(Puppet::Error, /You must specify a source/)
    end
  end

  context "protocol" do
    it "should accept any string value" do
      resource[:protocol] = 'git'
      resource[:protocol].should == 'git'
    end

    it "should default to the provider's default_protocol class method" do
    end
  end

  context "user" do
    it "should accept any string value" do
      resource[:user] = 'git'
      resource[:user].should == 'git'
    end

    it "should default to boxen_user if it exists" do
      Facter.stubs(:value).with(:boxen_user).returns(nil)
      Facter.stubs(:value).with(:id).returns(nil)
      factory.call(default_opts)[:user].should == "root"

      Facter.stubs(:value).with(:boxen_user).returns('testuser')
      factory.call(default_opts)[:user].should == 'testuser'
    end

    it "should override boxen_user if both exist" do
      Facter.stubs(:value).with(:boxen_user).returns('testuser')

      opts = default_opts.merge(:user => "otheruser")
      factory.call(opts)[:user].should == 'otheruser'
    end
  end

  context "extra" do
    it "should accept an array of extra options" do
      resource[:extra] = ['foo', 'bar']
      resource[:extra].should == ['foo', 'bar']
    end
  end
end
