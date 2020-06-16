require 'esign/request'

module Esign
  class Identity
    class << self
      # 个人银行四要素认证。因为没有让用户多录入银行预留手机号，所以直接用联系方式手机号。
      def identify_individual(name, id_no, bank_card_number, phone_number)
        Esign::Request.post_to_identity_with_token!(
            individual_url,
            { name: name, idNo: id_no, cardNo: bank_card_number, mobileNo: phone_number }
        )
      end

      def identify_enterprise(name, social_code, legal_person_name)
        Esign::Request.post_to_identity_with_token!(
            enterprise_url,
            { name: name, orgCode: social_code, legalRepName: legal_person_name }
        )
      end

      private

      def identity_host
        Esign.configuration.identity_host
      end

      def individual_url
        "https://#{identity_host}/v2/identity/verify/individual/bank4Factors"
      end

      def enterprise_url
        "https://#{identity_host}/v2/identity/verify/organization/enterprise/bureau3Factors"
      end
    end
  end
end
