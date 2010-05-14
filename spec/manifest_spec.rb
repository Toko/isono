require File.expand_path('../spec_helper', __FILE__)

require 'isono'

# force to load isono/manifest.rb using autoload.
Isono::Manifest

class MMStub < Isono::ManagerModules::Base
  config_section do 
    desc "conf1"
    conf1()
    desc "conf2"
    conf2()
  end
end

describe "Isono::Manifest Test" do

  it "define manifest" do
    m = Isono::Manifest.new('./') {
    }
    m.should.is_a? Isono::Manifest
    m.config.should.is_a? Isono::Manifest::ConfigStruct
  end

  it "config struct builder" do
    c = Isono::Manifest::ConfigStruct.new
    Isono::Manifest::ConfigStructBuilder.new(c) { |b|
      desc "aaa"
      aaa
      desc "bbb"
      bbb 1
      desc "ccc"
      b.ccc=2
      self.should.is_a? Isono::Manifest::ConfigStructBuilder
    }

    c.desc[:aaa].should.equal 'aaa'
    c.desc[:bbb].should.equal 'bbb'
    c.bbb.should.equal 1
    c.ccc.should.equal 2
  end
end
