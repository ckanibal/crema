# references.test.rb
require "cuba/test"
require "./references"
require "pp"

scope do
  test "should successfully parse the testcases" do
  	["test/parser001.txt"].each do |path|
  		s = IO.read(path)
  		refs = parse_references(s)
  		PP.pp(refs)
  	end
  end
end