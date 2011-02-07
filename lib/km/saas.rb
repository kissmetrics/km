require 'km'
class KM
  module SaaS
    def signed_up(plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record 'Signed Up', props
    end
    alias signedup signed_up

    def upgraded(plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record 'Upgraded', props
    end

    def downgraded(plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record 'Downgraded', props
    end

    def billed(amount=nil, description=nil, props={})
      props['Billing Amount']      = amount unless amount.to_s.empty?
      props['Billing Description'] = description unless description.to_s.empty?
      record 'Billed', props
    end

    def canceled(props={})
      record 'Canceled', props
    end
    alias cancelled canceled

    def visited_site(url=nil, referrer=nil, props={})
      props['URL']      = url unless url.to_s.empty?
      props['Referrer'] = referrer unless referrer.to_s.empty?
      record 'Visited Site', props
    end
    # ------------------------------------------------------------------------
  end
end
KM.send :extend, KM::SaaS
