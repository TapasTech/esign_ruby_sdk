require 'spec_helper'

RSpec.describe Esign::Contract do
  Esign.configure do |config|
    # 易签宝提供的沙盒环境测试账号
    config.contract_host = '120.55.107.58'
    config.app_id = '4438794221'
    config.app_secret = '7217066dc0eca92868c426becbd06139'
  end

  esign_account_id = ""

  context '创建易签宝账户' do
    it "can create personal esign account" do
      add_person_result = Esign::Contract.add_person(
                            '王广星',
                            '41092819900101239X'
                          )

      expect(add_person_result['errCode']).to be_zero 
      expect(add_person_result['accountId']).to be_truthy 
      expect(add_person_result['msg']).to eq '成功'
    end

    it "can create enterprise esign account" do
      enterprise_identify_result = Esign::Contract.add_organize(
                                     '深圳市腾讯计算机系统有限公司',
                                     '91440300708461136T'
                                   )

      esign_account_id = enterprise_identify_result['accountId']
      expect(enterprise_identify_result['errCode']).to be_zero
      expect(enterprise_identify_result['msg']).to eq '成功'
    end
  end

  context '创建签章' do
    it "can create enterprise seal" do
      create_seal_result = Esign::Contract.add_organize_seal(
                             esign_account_id 
                           )

      expect(create_seal_result['errCode']).to be_zero 
      expect(create_seal_result['sealData']).to be_truthy 
      expect(create_seal_result['msg']).to eq '成功'
    end
  end

  context '创建合同文件' do
    let(:text_fields) do
      {
        'party_b' => 'Party B',
        'party_b_phone' => '18902436654',
        'party_b_linkman' => '王小明',
        'email' => 'test@example.com',
        'party_b_linkman_phone' => '18902436654',
        'alipay_account' => 'alsdfksdf@qq.com',
        'nickname' => 'test nickname',
        'bank_account_name' => '王小明',
        'bank_name' => '招商银行',
        'sub_branch_name' => '招商上海支行',
        'bank_address' => '南京西路招商局广场',
        'bank_card_number' => '1245678765678',
        'date' => '2020-06-06'
      }
    end

    # it 'can complete template pdf' do
    #   _, complete_template_result = Esign::Contract.complete_template(
    #     'https://invest-crm-public.oss-cn-shanghai.aliyuncs.com/crm/attachments/20200429/9108cf9d8280-4aec-9d2b-3724383a6b8a',
    #     text_fields,
    #     esign_account_id
    #   )

    #   expect(complete_template_result['errCode']).to be_zero 
    #   expect(complete_template_result['stream']).to be_truthy 
    #   expect(complete_template_result['msg']).to eq '成功'
    # end

    it 'can create contract and produce a pdf file stream' do
      path = File.expand_path('../signature.png', __FILE__)
      seal = Base64.strict_encode64 File.read(path)
      _, contract_result = Esign::Contract.create_sign_file(
        'https://invest-crm-public.oss-cn-shanghai.aliyuncs.com/crm/attachments/20200429/9108cf9d8280-4aec-9d2b-3724383a6b8a',
        text_fields,
        esign_account_id,
        seal
      )

      expect(contract_result['errCode']).to be_zero 
      expect(contract_result['stream']).to be_truthy 
      expect(contract_result['msg']).to eq '成功'
    end
  end
end
