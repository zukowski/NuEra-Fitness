require 'spec_helper'

describe Address do
  before :each do
    @country = Country.create! :iso_name => 'US', :iso => 'US', :name => 'United States', :iso3 => 'USA', :numcode => '111'
    @state = State.create! :name => 'California', :abbr => 'CA', :country_id => @country.id

    @attr = {
      :firstname => 'test',
      :lastname => 'test',
      :address1 => 'po box 1111',
      :city => 'fubar',
      :zipcode => '90210',
      :country => @country,
      :phone => '5555555555'
    }
  end
      
  describe '#create' do
    it 'should recognize a state name and convert it to a state object' do
      @addr = Address.create! @attr.merge(:state_name => 'California')
      @addr.state.should == @state
    end

    it 'should recognize a state name ignoring case and convert it to a state object' do
      @addr = Address.create! @attr.merge(:state_name => 'california')
      @addr.state.should == @state
    end

    it 'should recognize a state abbr and convert it to a state object' do
      @addr = Address.create! @attr.merge(:state_name => 'CA')
      @addr.state.should == @state
    end

    it 'should recognize a state abbr ignoring case and convert it to a state object' do
      @addr = Address.create! @attr.merge(:state_name => 'ca')
      @addr.state.should == @state
    end
  end
end
