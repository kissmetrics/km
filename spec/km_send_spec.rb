require 'setup'

describe 'km_send' do
  context "using cron for sending logs" do
    before do
      now = Time.now
      Time.stub!(:now).and_return(now)
      Dir.glob(__('log','*')).each do |file|
        FileUtils.rm file
      end
      KM.reset
    end
    it "should test commandline version" do
      KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292', :use_cron => true
      KM::identify 'bob'
      KM::record 'Signup', 'age' => 26
      `bundle exec km_send #{__('log/')} 127.0.0.1:9292`
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
    end
  end
end
