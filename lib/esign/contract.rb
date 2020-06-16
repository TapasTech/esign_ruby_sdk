require 'base64'
require 'esign/request'
require 'open-uri'

module Esign
  class Contract
    class << self
      # 创建个人账户
      # params: name(string) 姓名, id_no(string) 身份证号码
      def add_person(name, id_no)
        Request.post_json(
          urls_map[:add_person],
          {
            name: name,
            idNo: id_no
          }.to_json
        )
      end

      # 创建企业账户
      # params: name(string) 企业名称, organ_code(string) 社会信用代码
      # 根据需求将默认企业注册类型改为社会信用代码
      def add_organize(name, organ_code, reg_type='MERGE')
        Request.post_json(
          urls_map[:add_organize],
          {
            name: name,
            organCode: organ_code,
            regType: reg_type
          }.to_json
        )
      end

      # 创建企业签章
      # params: account_id(string) 易签宝账户标识, color(string)签章颜色,
      # templateType(string) 模版类型, 默认为STAR标准公章
      # 易签宝文档: https://qianxiaoxia.yuque.com/books/share/6ef4d4ab-0699-4437-a9b8-e5e348937316/tnfbxb
      def add_organize_seal(account_id, color='RED', template_type='STAR')
        Request.post_json(
          urls_map[:add_organize_seal],
          {
            accountId: account_id,
            color: color,
            templateType: template_type
          }.to_json
        )
      end

      # 用合同模版进行甲乙双方签章
      # params: template_url(string) 合同模版url。
      #         text_fields(hash) 合同预填写信息，信息会填入模版PDF的预置文本域。
      #         account_id(string) 乙方易签宝account id, 从创建易签宝账户接口得到。
      #         bseal(string) 乙方签名图片的base64
      def create_sign_file(template_url, text_fields, account_id, bseal=nil)
        sign_a_tmp_file = "/tmp/contract_flow_a_#{account_id}.pdf"
        sign_b_tmp_file = "/tmp/contract_flow_b_#{account_id}.pdf"

        # 生成实际合同文件
        filled_tmp_file_path, _ = complete_template(template_url, text_fields, account_id)

        # 甲方签署
        sign_a_result = sign_a(filled_tmp_file_path)

        raise ServiceError.new("甲方签署失败: #{result['msg']}") unless sign_a_result['errCode'].zero?
        stream_a = sign_a_result['stream']

        # 甲方签署后的临时文件
        File.open(sign_a_tmp_file , 'w+') do |tfile|
          tfile << Base64.decode64(stream_a)
        end

        sign_b_result = user_stream_sign(sign_a_tmp_file, account_id, bseal)
        raise ServiceError.new("乙方签署失败: #{sign_b_result['msg']}") unless sign_b_result['errCode'].zero?
        stream_b = sign_b_result['stream']

        # 乙方签署后的临时文件
        File.open(sign_b_tmp_file , 'w+') do |tfile|
          tfile << Base64.decode64(stream_b)
        end

        [sign_b_tmp_file, sign_b_result]
      end

      # 填写合同预留字段
      # params: file(string) 合同模版文件path, text_fields(hash) 要填写的key/value值,
      # 其中key是pdf文件中占位的key, value为实际填写的值 
      def complete_template(template_url, text_fields, bid)
	tmp_file_path = "/tmp/contract_template_before_fill_#{bid}.pdf"
        filled_tmp_file_path = "/tmp/contract_template_dst#{bid}.pdf"

	# 下载初始模版
	File.open(tmp_file_path, 'w+') do |file|
	  file << open(template_url).read
	end

        tmp_file = File.open(tmp_file_path, 'r')
        resp = Request.post_multipart(
          urls_map[:create_from_template],
          [
            ['file', tmp_file],
            ['flatten', 'false'],
            ['txtFields', text_fields.to_json]
          ]
        )

        tmp_file.close
        stream = resp['stream']

	# 保存填充好的模版
	File.open(filled_tmp_file_path, 'w+') do |dst_file|
	  dst_file << Base64.decode64(stream)
	end

	[filled_tmp_file_path, resp]
      end

      # 甲方签署(平台自身签署)
      # params: file(string) 文件path, sign_type(string)签章类型, 默认为关键字方式
      #         seal_id(int)印章标识, 0为平台默认签章
      def sign_a(file_path, sign_type='Key',key='甲方签章', seal_id=0)
        file = File.open(file_path, 'r')
        params = [
          ['file', file],
          ['signType', sign_type],
          ['signPos', {key: key, posType: 1, posX: 100, posY: -10, width: 100}.to_json]
        ]

        result = Request.post_multipart(urls_map[:self_stream_sign], params)
        file.close

        result
      end

      # 平台用户签署
      def user_stream_sign(file_path, account_id, seal_data, sign_type='Key', key='party_b_signature')
        key = '乙方签章'

        file = File.open(file_path, 'r')
        params = [
          ['file', file],
          ['accountId', account_id],
          ['signType', sign_type],
          ['signPos', {key: key, posType: 1, posX: 100, posY: -10, width: 100}.to_json]
        ]

        if seal_data
          params = params.push(['sealData', seal_data])
        end

        result = Request.post_multipart(urls_map[:user_stream_sign], params)

        file.close
        result
      end

      private

      def urls_map
        {
          add_person: url_from_path('account/addPerson'),
          add_organize: url_from_path('account/addOrganize'),
          add_organize_seal: url_from_path('seal/addOrganizeSeal'),
          create_from_template: url_from_path('doc/stream/createFromTemplate'),
          self_stream_sign: url_from_path('sign/selfStreamSign'),
          user_stream_sign: url_from_path('sign/userStreamSign')
        }
      end

      def url_from_path(path)
        "http://#{esign_host}/tech-sdkwrapper/timevale/#{path}"
      end

      def esign_host
        Esign.configuration.contract_host
      end
    end
  end
end
