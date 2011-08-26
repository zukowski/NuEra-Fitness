require 'spec_helper'

describe Address do
  # Associations
  it { should belong_to :country }
  it { should belong_to :state }
  it { should have_many :shipments }

  # Validations
  it { should validate_presence_of :state }
  it 'should not validate presence of state when a state name is given' do
    @addr = Address.new @attr.merge(:state_name => 'test', :country => @nostate_country)
    @addr.should_not validate_presence_of :state
  end
  it { should validate_presence_of :state_name }
  it 'should not validate presence of state name when a state is given' do
    @addr = Address.new @attr.merge(:state => @state)
    @addr.should_not validate_presence_of :state_name
  end
  it { should validate_presence_of :firstname }
  it { should validate_presence_of :lastname }
  it { should validate_presence_of :address1 }
  it { should validate_presence_of :city }
  it { should validate_presence_of :zipcode }
  it { should validate_presence_of :country }
  it { should validate_presence_of :phone }

  before :each do
    @nostate_country = Country.create! :iso_name => 'CA', :iso => 'CA', :name => 'Canada', :iso3 => 'CAN', :numcode => '222'
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

    it 'should leave the state alone if a state_id is given' do
      @addr = Address.create! @attr.merge(:state_id => @state.id)
      @addr.state.should == @state
    end

    it 'should not be valid if neither a state or state_name are given' do
      @addr = Address.new @attr
      @addr.should_not be_valid
    end

    it 'should not be valid if the state name isnt mappable to a known state' do
      @addr = Address.new @attr.merge(:state_name => 'abracadabra')
      @addr.should_not be_valid
    end
  end
end
