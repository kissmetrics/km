require 'setup'

describe KM do
  attr_accessor :send_query, :log
  before do
    @send_query = []
    @log = []
    KM.stub(:send_query).and_return { |*args| send_query << args }
    KM.stub(:log).and_return { |*args| log << Hash[*args] }
    time = Time.at 1234567890
    Time.stub!(:now).and_return(time)
    KM.reset
  end
  context "initialization" do
    it "should not record without initialization" do
      KM::record 'My Action'
      log.first[:error].should =~ /Need to initialize first \(KM::init <your_key>\)/
    end
    it "should not set initialization" do
      KM::set :day => 'friday'
      log.first[:error].should =~ /Need to initialize first \(KM::init <your_key>\)/
    end
  end
  context "identification" do
    before do
      KM::init 'KM_KEY'
    end
    it "should not record without identification" do
      KM::record 'My Action'
      log.first[:error].should include("Need to identify first (KM::identify <user>)")
    end
    it "should set without identification" do
      KM::record 'My Action'
      log.first[:error].should include("Need to identify first (KM::identify <user>)")
    end

    context "aliasing" do
      it "shouldn't fail on alias without identifying" do
        KM::alias 'peter','joe' # Alias "bob" to "robert"
        send_query.first.first.should have_query_string("/a?_n=joe&_p=peter&_k=KM_KEY&_t=1234567890")
      end
    end
  end

  context "events" do
    before do
      KM::init 'KM_KEY'
      KM::identify 'bob'
    end
    it "should record an action with no specific props" do
      KM::record 'My Action'
      send_query.first.first.should have_query_string("/e?_n=My+Action&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should record an action with properties" do
      KM::record 'Signup', 'age' => 26
      send_query.first.first.should have_query_string("/e?age=26&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should reocrd properties with spaces in key and value" do
      KM::record 'Signup', 'age' => 26, 'city of residence' => 'eug ene'
      send_query.first.first.should have_query_string("/e?age=26&city+of+residence=eug+ene&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should not over-write special keys" do
      KM::record 'Signup', 'age' => 26, '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      send_query.first.first.should have_query_string("/e?age=26&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should not over-write special keys with symbols" do
      KM::record 'Signup', 'age' => 26, '_p' => 'billybob', :'_k' => 'foo', :'_n' => 'something else'
      send_query.first.first.should have_query_string("/e?age=26&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should work with properties with @" do
      KM::record 'Signup', 'email' => 'test@blah.com', '_p' => 'billybob', '_k' => 'foo', '_n' => 'something else'
      send_query.first.first.should have_query_string("/e?email=test%40blah.com&_p=bob&_k=KM_KEY&_n=Signup&_t=1234567890")
    end
    it "should work with just set" do
      KM::record 'age' => 26
      send_query.first.first.should have_query_string("/s?age=26&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "should record ok with multiple calls" do
      KM::record 'Signup', 'age' => 26
      KM::record 'Signup', 'age' => 36
      send_query.first.first.should have_query_string("/e?age=26&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567890")
    end
    it "shouldn't store the key anywhere" do
      KM::init 'KM_OTHER'
      KM::alias 'truman','harry' # Alias "bob" to "robert"
      send_query.first.first.should have_query_string("/a?_n=harry&_p=truman&_k=KM_OTHER&_t=1234567890")
    end
    it "should override the time if defined" do
      KM::record 'Signup', 'age' => 36, '_t' => 1234567891
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567891&_d=1")
    end
    it "should work with either symbols or strings" do
      KM::record :Signup, :age => 36, :_t => 1234567891
      send_query.last.first.should have_query_string("/e?age=36&_n=Signup&_p=bob&_k=KM_KEY&_t=1234567891&_d=1")
    end
  end

  it "should test cron" do
    pending
  end
  it "should send logged queries" do
    pending
  end
end
