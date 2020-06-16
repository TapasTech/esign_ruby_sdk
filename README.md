# EsignIdentity

易签宝ruby SDK, 核心功能有:
- 个人三要素认证
- 企业四要素认证
- 通过易签宝为甲乙双方签约

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esign_ruby_sdk', git: 'git@github.com:TapasTech/esign_ruby_sdk.git', branch: 'master'
```

And then execute:

    $ bundle install

## Usage

```ruby
Esign.configure do |config|
  config.app_id = 'xxxxx'  
  config.app_secret = 'xxxx'  
  config.identity_host = 'xxxx' # 认证服务地址 
  config.contract_host = 'xxxx' # 签约服务地址 
end

# 个人身份认证
EsignIdentity.identify_individual(name, id_no, bank_card_number, phone_number)
  
# 企业身份认证
EsignIdentity.identify_enterprise(name, social_code, legal_person_name)

# 代创建易签宝个人账户
# params: name(string) 姓名, id_no(string) 身份证号码
EsignContract.add_person(name, id_no)

# 代创建企业易签宝账户
# params: name(string) 企业名称, organ_code(string) 社会信用代码
# 根据需求将默认企业注册类型改为社会信用代码
EsignContract.add_organize(name, organ_code)

# 创建企业签章
# params: account_id(string) 易签宝账户标识, color(string)签章颜色,
# templateType(string) 模版类型, 默认为STAR标准公章
# 易签宝文档: https://qianxiaoxia.yuque.com/books/share/6ef4d4ab-0699-4437-a9b8-e5e348937316/tnfbxb
EsignContract.add_organize_seal(account_id)

# 用合同模版进行甲乙双方签章
# params: template_url(string) 合同模版url。
#         text_fields(hash) 合同预填写信息，信息会填入模版PDF的预置文本域。
#         account_id(string) 乙方易签宝account id, 从创建易签宝账户接口得到。
#         bseal(string) 乙方签名图片的base64
EsignContract.create_sign_file(template_url, text_fields, account_id, bseal)

# 也可分步进行(自行处理中间环节PDF文件):
# 1. 填充合同模版:
EsignContract.complete_template(template_url, text_fields, bseal)
# 2. 甲方签署:
EsignContract.sign_a(file_path, sign_type)
# 3. 乙方签署:
EsignContract.sign_a(file_path, account_id, seal_data)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Test
```
bundle exec rspec spec/
```
