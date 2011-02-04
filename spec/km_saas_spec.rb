require 'setup'
require 'km/saas'
describe KM do
  before do
    KM::reset
    now = Time.now
    Time.stub!(:now).and_return(now)
    FileUtils.rm_f KM::log_name(:error)
    FileUtils.rm_f KM::log_name(:query)
    Helper.clear
  end

  describe "should record events" do
    before do
      KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292'
      KM::identify 'bob'
    end
    it "records a signup event" do
      KM.signed_up 'Premium'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Signed Up'
      res[:query]['Plan Name'].first.should == 'Premium'
    end
    it "records an upgraded event" do
      KM.upgraded 'Unlimited'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Upgraded'
      res[:query]['Plan Name'].first.should == 'Unlimited'
    end
    it "records a downgraded event" do
      KM.downgraded 'Free'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Downgraded'
      res[:query]['Plan Name'].first.should == 'Free'
    end
    it "records a billed event" do
      KM.billed 32, 'Upgraded'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Billed'
      res[:query]['Billing Amount'].first.should == '32'
      res[:query]['Billing Description'].first.should == 'Upgraded'
    end
    it "records a canceled event" do
      KM.canceled
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Canceled'
    end
    it "records a cancelled event" do
      KM.cancelled
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Canceled'
    end
    it "records a visited site event" do
      KM.visited_site 'http://duckduckgo.com', 'http://daniel.bretoi.com'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_n'].first.should == 'Visited Site'
      res[:query]['URL'].first.should == 'http://duckduckgo.com'
      res[:query]['Referrer'].first.should == 'http://daniel.bretoi.com'
    end
  end
end
