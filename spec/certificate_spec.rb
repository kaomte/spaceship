require 'spec_helper'

describe Spaceship::Certificate do
  before { Spaceship.login }
  let(:client) { Spaceship::Certificate.client }

  describe "successfully loads and parses all certificates" do
    it "the number is correct" do
      expect(Spaceship::Certificate.all.count).to eq(3)
    end

    it "parses code signing identities correctly" do
      cert = Spaceship::Certificate.all.first

      expect(cert.id).to eq('XC5PH8DAAA')
      expect(cert.name).to eq('SunApps GmbH')
      expect(cert.status).to eq('Issued')
      expect(cert.created.to_s).to eq('2014-11-25T22:55:50Z')
      expect(cert.expires.to_s).to eq('2015-11-25T22:45:50Z')
      expect(cert.owner_type).to eq('team')
      expect(cert.owner_name).to eq('SunApps GmbH')
      expect(cert.owner_id).to eq('5A997XSAAA')
      expect(cert.is_push).to eq(false)
    end

    it "parses push certificates correctly" do
      push = Spaceship::Certificate.find('32KPRBAAAA') # that's the push certificate

      expect(push.id).to eq('32KPRBAAAA')
      expect(push.name).to eq('net.sunapps.54')
      expect(push.status).to eq('Issued')
      expect(push.created.to_s).to eq('2015-04-02T21:34:00Z')
      expect(push.expires.to_s).to eq('2016-04-01T21:24:00Z')
      expect(push.owner_type).to eq('bundle')
      expect(push.owner_name).to eq('Timelack')
      expect(push.owner_id).to eq('3599RCHAAA')
      expect(push.is_push).to eq(true)
    end
  end

  it "Correctly filters the listed certificates" do
    certs = Spaceship::Certificate::Development.all
    expect(certs.count).to eq(1)

    cert = certs.first
    expect(cert.id).to eq('C8DL7464RQ')
    expect(cert.name).to eq('Felix Krause')
    expect(cert.status).to eq('Issued')
    expect(cert.created.to_s).to eq('2014-11-25T22:55:50Z')
    expect(cert.expires.to_s).to eq('2015-11-25T22:45:50Z')
    expect(cert.owner_type).to eq('teamMember')
    expect(cert.owner_name).to eq('Felix Krause')
    expect(cert.owner_id).to eq('5Y354CXU3A')
    expect(cert.is_push).to eq(false)
  end

  describe '#download' do
    let(:cert) { Spaceship::Certificate.all.first }
    it 'downloads the associated .cer file' do
      x509 = OpenSSL::X509::Certificate.new(cert.download)
      expect(x509.issuer.to_s).to match('Apple Worldwide Developer Relations')
    end
  end

  describe '#revoke' do
    let(:cert) { Spaceship::Certificate.all.first }
    it 'revokes certificate by the given cert id' do
      expect(client).to receive(:revoke_certificate).with('XC5PH8DAAA', 'R58UK2EAAA')
      cert.revoke
    end
  end

  describe '#create' do
    it 'should create and return a new certificate' do
      expect(client).to receive(:create_certificate).with('3BQKVH9I2X', /BEGIN CERTIFICATE REQUEST/, 'B7JBD8LHAA') {
        JSON.parse(read_fixture_file('certificateCreate.certRequest.json'))
      }
      certificate = Spaceship::Certificate::ProductionPush.create(Spaceship::Certificate.certificate_signing_request.first, 'net.sunapps.151')
      expect(certificate).to be_instance_of(Spaceship::Certificate::ProductionPush)
    end
  end
end