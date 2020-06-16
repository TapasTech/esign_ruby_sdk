require 'spec_helper'

RSpec.describe Esign::Identity do
  Esign.configure do |config|
    config.identity_host = 'smlopenapi.esign.cn'
    config.app_id = '4438794221'
    config.app_secret = '7217066dc0eca92868c426becbd06139'
  end

  it "can identify personal identity" do
    expect(Esign::Identity.identify_individual(
      '王小明',
      '440785199909090909',
      '6226889023457896',
      '18989898989'
    ).keys).to contain_exactly('code', 'data', 'message') 
  end

  it "can identify enterprise identity" do
    enterprise_identify_result = Esign::Identity.identify_enterprise(
                                   '深圳市腾讯计算机系统有限公司',
                                   '91440300708461136T',
                                   '马化腾'
                                 )

    expect(enterprise_identify_result['code']).to be_zero
    expect(enterprise_identify_result['message']).to eq '成功'
  end
end
