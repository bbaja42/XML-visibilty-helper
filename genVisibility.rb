#!/usr/bin/env ruby

require 'trollop'
require 'active_support/core_ext'

opts = Trollop::options do
  opt :start, "Start time", :default => Time.now.to_s       # string --start, default now
  opt :end, "End time", :default => (Time.now + 1.day).to_s       # string --start, default now
  opt :period, "Reschedule acquisition every X minutes", :default => 15   # integer --acq_period <i>, default to 15
  opt :duration, "Acquisition duration", :default => 1 # integer --acq_duration <i>, default 1
  opt :file_name, "Output xml file name", :default => "visibility.xml" # string --file_name, default 1
end

Trollop::die :start, "must be parsable by ruby datetime" unless DateTime.parse(opts[:start]).to_time
Trollop::die :end, "must be parsable by ruby datetime" unless DateTime.parse(opts[:end]).to_time
Trollop::die :period, "must be positive" unless opts[:period] > 0
Trollop::die :duration, "must be positive" unless opts[:duration] > 0
Trollop::die :period, "must be at least twice the duration size" if opts[:period] < 2 * opts[:duration]
Trollop::die :end, "must be after start time" unless opts[:end] > opts[:start]

p opts
start_time = DateTime.parse(opts[:start]).to_time
end_time = DateTime.parse(opts[:end]).to_time


start_block = <<HERE
<?xml version = "1.0" encoding = "UTF-8"?>
<XSVE_Visibility_File
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:noNamespaceSchemaLocation='VISIBILITY_SCHEMA.XSD'
>
  <XSVE_Visibility_Header>
    <Fixed_Header>
      <File_Name>SAMPLE_VISIBILITY.XML</File_Name>
      <Validity_Period>
        <Validity_Start>2011-01-01T02:00:02</Validity_Start>
        <Validity_Stop>2012-01-01T17:25:29</Validity_Stop>
      </Validity_Period>
      <!-- Basic information about the source of the configuration files -->
      <Source>
        <System>File Generator</System>
        <Creator>VisibilityFile Generator</Creator>
        <Creator_Version>2.0-SNAPSHOT</Creator_Version>
        <Creation_Date>UTC=2010-11-15T14:52:54</Creation_Date>
      </Source>
    </Fixed_Header>
  </XSVE_Visibility_Header>
  <Data_Block type="xml">
    <Utf>
      <List_of_Segments>
HERE

end_block = <<HERE
      </List_of_Segments>
    </Utf>
  </Data_Block>
</XSVE_Visibility_File>
HERE

#
#create xml segment with start and end time
def create_segment(start_time, end_time)
  xml_start = <<HERE
  <Segment>
            <Start><!-- Time format : yyyy-MM-ddTHH:mm:ss:SSS -->
HERE
  xml_mid = <<HERE
            </Start>
            <Stop><!-- Time format : yyyy-MM-ddTHH:mm:ss:SSS -->
HERE
  xml_end = <<HERE
            </Stop>
  </Segment>
HERE
  time_format="%Y-%m-%dT%H:%M:%S:%L"
  utc_start="               <UTC>" + start_time.strftime(time_format) + "</UTC>\n"
  utc_end="               <UTC>" + end_time.strftime(time_format) + "</UTC>\n"
  document = xml_start + utc_start + xml_mid + utc_end + xml_end
end


segments = ""
while start_time < end_time
  start_time = start_time + opts[:period].minute
  segments += create_segment(start_time, start_time + opts[:duration].minute)
end

xml_content = start_block + segments + end_block
File.open(opts[:file_name], 'w') {|f| f.write(xml_content) }
