require 'km'
class KM
  module SaaS
    def signed_up(id, plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record id, 'Signed Up', props
    end
    alias signedup signed_up

    def upgraded(id, plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record id, 'Upgraded', props
    end

    def downgraded(id, plan=nil, props = {})
      props['Plan Name'] = plan unless plan.to_s.empty?
      record id, 'Downgraded', props
    end

    def billed(id, amount=nil, description=nil, props={})
      props['Billing Amount']      = amount unless amount.to_s.empty?
      props['Billing Description'] = description unless description.to_s.empty?
      record id, 'Billed', props
    end

    def canceled(id, props={})
      record id, 'Canceled', props
    end
    alias cancelled canceled

    def visited_site(id, url=nil, referrer=nil, props={})
      props['URL']      = url unless url.to_s.empty?
      props['Referrer'] = referrer unless referrer.to_s.empty?
      record id, 'Visited Site', props
    end
    # ------------------------------------------------------------------------
  end
end
KM.send :extend, KM::SaaS
