require 'spec_helper'

describe CandyCheck::PlayStore::Client do
  include WithFixtures

  subject { CandyCheck::PlayStore::Client.new(config) }

  let(:config) do
    CandyCheck::PlayStore::Config.new(
      application_name: 'demo_app',
      application_version: '1.0',
      issuer: 'test_issuer',
      key_file: fixture_path('play_store', 'dummy.p12'),
      key_secret: 'notasecret'
    )
  end

  it 'fails if authentication fails' do
    mock_authorize!('auth_failure.txt')
    proc { subject.boot! }.must_raise Signet::AuthorizationError
  end

  it 'returns the products call result\'s data even if it is a failure' do
    bootup!

    mock_request!('products_failure.txt')
    result = subject.verify('the_package', 'the_id', 'the_token')
    result.must_be_instance_of Hash

    result['error']['code'].must_equal 401
    result['error']['message'].must_equal 'The current user has insufficient' \
      ' permissions to perform the requested operation.'
    result['error']['errors'].size.must_equal 1
  end

  it 'returns the products call result\'s data for a successful call' do
    bootup!
    mock_request!('products_success.txt')
    result = subject.verify('the_package', 'the_id', 'the_token')
    result.must_be_instance_of Hash
    result['purchaseState'].must_equal 0
    result['consumptionState'].must_equal 0
    result['developerPayload'].must_equal \
      'payload that gets stored and returned'
    result['purchaseTimeMillis'].must_equal '1421676237413'
    result['kind'].must_equal 'androidpublisher#productPurchase'
  end

  private

  def bootup!
    mock_authorize!('auth_success.txt')
    subject.boot!
  end

  def mock_authorize!(file)
    stub_request(:post, 'https://accounts.google.com/o/oauth2/token')
      .to_return(fixture_content('play_store', file))
  end

  def mock_request!(file)
    stub_request(:get, 'https://www.googleapis.com/androidpublisher/v2/' \
      'applications/the_package/purchases/products/the_id/tokens/the_token')
      .to_return(fixture_content('play_store', file))
  end
end
