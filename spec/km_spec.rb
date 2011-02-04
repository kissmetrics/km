require 'setup'
describe KM do
  before do
    KM::reset
    now = Time.now
    Time.stub!(:now).and_return(now)
    FileUtils.rm_f KM::log_name(:error)
    FileUtils.rm_f KM::log_name(:query)
    Helper.clear
  end
  it "shouldn't write at all without init or identify" do
    KM::record 'My Action'
    IO.readlines(KM::log_name(:error)).join.should =~ /Need to initialize first \(KM::init <your_key>\)/

    FileUtils.rm_f KM::log_name(:error)
    KM::set :day => 'friday'
    IO.readlines(KM::log_name(:error)).join.should =~ /Need to initialize first \(KM::init <your_key>\)/

    KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292'
    FileUtils.rm_f KM::log_name(:error)
    KM::record 'My Action'
    IO.readlines(KM::log_name(:error)).last.should =~ /Need to identify first \(KM::identify <user>\)/

    FileUtils.rm_f KM::log_name(:error)
    KM::set :day => 'friday'
    IO.readlines(KM::log_name(:error)).last.should =~ /Need to identify first \(KM::identify <user>\)/
  end

  it "shouldn't fail on alias without identifying" do
    KM::init 'KM_OTHER', :log_dir => __('log'), :host => '127.0.0.1:9292'
    KM::alias 'peter','joe' # Alias "bob" to "robert"
    sleep 0.1
    res = Helper.accept(:history).first.indifferent
    res[:path].should == '/a'
    res[:query]['_k'].first.should == 'KM_OTHER'
    res[:query]['_p'].first.should == 'peter'
    res[:query]['_n'].first.should == 'joe'
    res[:query]['_t'].first.should == Time.now.to_i.to_s
  end
  it "shouldn't fail on alias without identifying from commandline" do
    KM::init 'KM_OTHER', :log_dir => __('log'), :host => '127.0.0.1:9292'
    KM::alias 'peter','joe' # Alias "bob" to "robert"
    sleep 0.1
    res = Helper.accept(:history).first.indifferent
    res[:path].should == '/a'
    res[:query]['_k'].first.should == 'KM_OTHER'
    res[:query]['_p'].first.should == 'peter'
    res[:query]['_n'].first.should == 'joe'
    res[:query]['_t'].first.should == Time.now.to_i.to_s
  end

  describe "should record events" do
    before do
      KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292'
      KM::identify 'bob'
    end
    it "records an action with no action-specific properties" do
      KM::record 'My Action'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'My Action'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
    end
    it "records an action with properties" do
      KM::record 'Signup', 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
    end
    it "should be able to hace spaces in key and value" do
      KM::record 'Signup', 'age' => 26, 'city of residence' => 'eug ene'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
      res[:query]['city of residence'].first.should == 'eug ene'
    end
    it "should not override important parts" do
      KM::record 'Signup', 'age' => 26, '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
    end
    it "should work with propps using @" do
      KM::record 'Signup', 'email' => 'test@blah.com', '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['email'].first.should == 'test@blah.com'
    end
    it "should just set properties without event" do
      KM::record 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/s'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
    end
    it "should be able to use km set directly" do
      KM::set 'age' => 26
      sleep 0.1
      res = Helper.accept(:history).first.indifferent
      res[:path].should == '/s'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
    end
    it "should work with multiple lines" do
      # testing recording of multiple lines.
      KM::record 'Signup', 'age' => 26
      sleep 0.1
      KM::record 'Signup', 'age' => 36
      sleep 0.1
      res = Helper.accept(:history)[0].indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_n'].first.should == 'Signup'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 26.to_s
      res = Helper.accept(:history)[1].indifferent
      res[:path].should == '/e'
      res[:query]['_k'].first.should == 'KM_KEY'
      res[:query]['_p'].first.should == 'bob'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
      res[:query]['age'].first.should == 36.to_s
    end
    it "should not have key hardcoded anywhere" do
      KM::init 'KM_OTHER', :log_dir => __('log')
      KM::alias 'truman','harry' # Alias "bob" to "robert"
      sleep 0.1
      res = Helper.accept(:history)[0].indifferent
      res[:path].should == '/a'
      res[:query]['_k'].first.should == 'KM_OTHER'
      res[:query]['_p'].first.should == 'truman'
      res[:query]['_n'].first.should == 'harry'
      res[:query]['_t'].first.should == Time.now.to_i.to_s
    end
  end
  context "reading from files" do
    before do
      Dir.glob(__('log','*')).each do |file|
        FileUtils.rm file
      end
      KM.reset
    end
    it "should run fine even though there's no server to connect to" do
      KM::init 'KM_OTHER', :log_dir => __('log'), :host => '127.0.0.1:9291', :to_stderr => false
      KM::identify 'bob'
      KM::record 'My Action' # records an action with no action-specific properties;
      Helper.accept(:history).count.should == 0
      File.exists?(__('log/kissmetrics_query.log')).should == true
      File.exists?(__('log/kissmetrics_error.log')).should == true
    end

    it "should escape @ properly" do
      KM::init 'KM_OTHER', :log_dir => __('log'), :host => '127.0.0.1:9292', :to_stderr => false, :use_cron => true
      KM::identify 'bob'
      KM::record 'prop_with_@_in' # records an action with no action-specific properties;
      IO.readlines(KM::log_name(:query)).join.should_not contain_string('@')
    end
  end
end
