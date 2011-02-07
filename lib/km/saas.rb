require 'km'
class KM
  module SaaS
    def signed_up(plan=nil, props = {})
      props['Plan Name'] = plan if plan
      record 'Signed Up', props
    end
    alias signedup signed_up

    def upgraded(plan=nil, props = {})
      props['Plan Name'] = plan if plan
      record 'Upgraded', props
    end

    def downgraded(plan=nil, props = {})
      props['Plan Name'] = plan if plan
      record 'Downgraded', props
    end

    def billed(amount=nil, description=nil, props={})
      props['Billing Amount']      = amount if amount
      props['Billing Description'] = description if description
      record 'Billed', props
    end

    def canceled(props={})
      record 'Canceled', props
    end
    alias cancelled canceled

    def visited_site(url=nil, referrer=nil, props={})
      props['URL']      = url if url
      props['Referrer'] = referrer if referrer
      record 'Visited Site', props
    end
    # ------------------------------------------------------------------------
  end
end
KM.send :extend, KM::SaaS
