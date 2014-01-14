describe 'InstagramClient' do

  before do
  end

  after do
  end

  it 'should create instance' do
    InstagramClient.create.is_a?(InstagramClient).should == true
  end
end
