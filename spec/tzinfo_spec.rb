require 'spec_helper'
require_relative '../lib/icalendar/tzinfo'

describe 'TZInfo::Timezone' do

  let(:tz) { TZInfo::Timezone.get 'Europe/Copenhagen' }
  let(:date) { DateTime.new 1970 }
  subject { tz.ical_timezone date }

  describe 'daylight offset' do
    specify { expect(subject.daylights.first.tzoffsetto.value_ical).to eq "+0200" }
    specify { expect(subject.daylights.first.tzoffsetfrom.value_ical).to eq "+0100" }
  end

  describe 'standard offset' do
    specify { expect(subject.standards.first.tzoffsetto.value_ical).to eq "+0100" }
    specify { expect(subject.standards.first.tzoffsetfrom.value_ical).to eq "+0200" }
  end

  describe 'no end transition' do
    let(:tz) { TZInfo::Timezone.get 'America/Cayman' }
    let(:date) { DateTime.now }

    it 'only creates a standard component' do
      expect(subject.to_ical).to eq <<-EXPECTED.gsub "\n", "\r\n"
BEGIN:VTIMEZONE
TZID:America/Cayman
BEGIN:STANDARD
DTSTART:19120201T000711
TZOFFSETFROM:-0652
TZOFFSETTO:-0500
TZNAME:EST
END:STANDARD
END:VTIMEZONE
      EXPECTED
    end
  end

  describe 'no transition' do
    let(:tz) { TZInfo::Timezone.get 'UTC' }
    let(:date) { DateTime.now }

    it 'creates a standard component with equal offsets' do
      expect(subject.to_ical).to eq <<-EXPECTED.gsub "\n", "\r\n"
BEGIN:VTIMEZONE
TZID:UTC
BEGIN:STANDARD
DTSTART:19700101T000000
TZOFFSETFROM:+0000
TZOFFSETTO:+0000
TZNAME:UTC
END:STANDARD
END:VTIMEZONE
      EXPECTED
    end
  end

  describe 'dst transition' do
    subject { TZInfo::Timezone.get 'America/Los_Angeles' }
    let(:now) { subject.now }
    # freeze in DST transition in America/Los_Angeles
    before(:each) { Timecop.freeze DateTime.new(2013, 11, 03, 1, 30, 0, '-08:00') }
    after(:each) { Timecop.return }

    specify { expect { subject.ical_timezone now, nil }.to raise_error TZInfo::AmbiguousTime }
    specify { expect { subject.ical_timezone now, true }.not_to raise_error }
    specify { expect { subject.ical_timezone now, false }.not_to raise_error }

    context 'TZInfo::Timezone.default_dst = nil' do
      before(:each) { TZInfo::Timezone.default_dst = nil }
      specify { expect { subject.ical_timezone now }.to raise_error TZInfo::AmbiguousTime }
    end

    context 'TZInfo::Timezone.default_dst = true' do
      before(:each) { TZInfo::Timezone.default_dst = true }
      specify { expect { subject.ical_timezone now }.not_to raise_error }
    end

    context 'TZInfo::Timezone.default_dst = false' do
      before(:each) { TZInfo::Timezone.default_dst = false }
      specify { expect { subject.ical_timezone now }.not_to raise_error }
    end
  end

end
