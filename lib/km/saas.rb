require 'km'
class KM
  module SaaS
    #------------------------------------------------------------------------
    def signed_up(plan=nil, props = {})
      record 'Signed Up', {'Plan Name' => plan}.merge(props)
    end
    alias signedup signed_up
    #------------------------------------------------------------------------
    def upgraded(plan=nil, props = {})
      record 'Upgraded', {'Plan Name' => plan}.merge(props)
    end
    #------------------------------------------------------------------------
    def downgraded(plan=nil, props = {})
      record 'Downgraded', {'Plan Name' => plan}.merge(props)
    end
    #------------------------------------------------------------------------
    def billed(amount=nil, description=nil, props={})
      record 'Billed', {'Billing Amount' => amount, 'Billing Description' => description}.merge(props)
    end
    #------------------------------------------------------------------------
    def canceled(props={})
      record 'Canceled', props
    end
    alias cancelled canceled
    #------------------------------------------------------------------------
    def visited_site(url=nil, referrer=nil, props={})
      record 'Visited Site', {'URL' => url, 'Referrer' => referrer}.merge(props)
    end
    #------------------------------------------------------------------------
  end
end
KM.send :extend, KM::SaaS
