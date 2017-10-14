#!/usr/bin/env ruby

def parse_references(response)
  document = Hash.new
  stack = [document]
  current_indent = -1

  response.each_line do |line|
    if(line.strip.empty?)
      next
    end

    indent_level = line.count(' ')-line.lstrip.count(' ')
    if(indent_level < current_indent)
      stack.shift((current_indent - indent_level)/2)
      current_indent = indent_level
    end

    if line.lstrip.start_with? '['
      if(indent_level == current_indent)
        stack.shift()
      end
      key = line.tr("[]\n ", '')
      value = Hash.new
      parent = stack.first
      if parent.has_key? key
        if parent[key].is_a?(Hash)
          parent[key] = [parent[key]]
        end
        parent[key] << value
      else
        parent[key] = value
      end
      stack.unshift(value)
    else
      (key, value) = line.strip.split('=')
      parent = stack.first
      parent[key] = value
    end
    current_indent = indent_level
  end
  return document
end
