require 'net/http'
require 'uri'
require 'json'
require 'digest'

class FileStoreClient
  BASE_URL = 'http://localhost:3000/stored_files'

  def self.add(*file_paths)
    file_paths.each do |file_path|
      puts "Processing file: #{file_path}" # Log file being processed
  
      full_path = File.expand_path(file_path, __dir__)
      unless File.exist?(full_path)
        puts "Error: File '#{full_path}' does not exist."
        next
      end
  
      file_hash = Digest::SHA256.file(full_path).hexdigest
      file_name = File.basename(full_path) # Use file name for new entry
      puts "Computed hash for #{file_path}: #{file_hash}" # Log computed hash
  
      # Check if the file hash exists on the server
      uri = URI("#{BASE_URL}/check_hash")
      request = Net::HTTP::Post.new(uri)
      request.body = { file_hash: file_hash }.to_json
      request['Content-Type'] = 'application/json'
  
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      puts "Hash check response for #{file_path}: #{response.code}, #{response.body}" # Log response from server
  
      if response.code.to_i == 200 && JSON.parse(response.body)['match']
        # File with the same content exists, send only the name for the new entry
        puts "File with the same content already exists. Sending new name: #{file_name}"
        uri = URI(BASE_URL)
        request = Net::HTTP::Post.new(uri)
        request.body = { name: file_name, file_hash: file_hash }.to_json
        request['Content-Type'] = 'application/json'
  
        response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
        puts "Response for reusing existing content: #{response.body}"
        next
      end
  
      # Upload the file as it's not present on the server
      file = File.open(full_path)
      begin
        puts "Uploading file: #{file_path}" # Log upload action
        uri = URI(BASE_URL)
        request = Net::HTTP::Post.new(uri)
        form_data = [['file', file]]
        request.set_form(form_data, 'multipart/form-data')
  
        response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
        puts "Upload response for #{file_path}: #{response.code}, #{response.body}" # Log upload response
      ensure
        file&.close
        puts "Closed file: #{file_path}" # Log file closure
      end
    end
  end

  def self.list
    uri = URI(BASE_URL)
    response = Net::HTTP.get_response(uri)
    puts response.body
  end

  def self.update(file_path)
    full_path = File.expand_path(file_path, __dir__)
    unless File.exist?(full_path)
      puts "Error: File '#{full_path}' does not exist."
      return
    end

    file_name = File.basename(full_path) # Infer file name from the path
    file_hash = Digest::SHA256.file(full_path).hexdigest
    uri = URI("#{BASE_URL}/check_hash")
    request = Net::HTTP::Post.new(uri)
    request.body = { file_hash: file_hash }.to_json
    request['Content-Type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
    if response.code.to_i == 200 && JSON.parse(response.body)['match']
      puts 'No update needed. File contents are identical.'
      return
    end

    # Proceed with upload if hash doesn't match
    file = File.open(full_path)
    begin
      uri = URI("#{BASE_URL}/#{file_name}")
      request = Net::HTTP::Put.new(uri)
      form_data = [['file', file]]
      request.set_form(form_data, 'multipart/form-data')

      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      puts response.body
    ensure
      file&.close
    end
  end

  def self.delete(file_name)
    uri = URI("#{BASE_URL}/#{file_name}")
    request = Net::HTTP::Delete.new(uri)

    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
    puts response.body
  end

  def self.word_count
    uri = URI("#{BASE_URL}/word_count")
    response = Net::HTTP.get_response(uri)
    puts response.body
  end

  def self.freq_words(limit = 10, order = 'desc')
    uri = URI("#{BASE_URL}/freq_words?limit=#{limit}&order=#{order}")
    response = Net::HTTP.get_response(uri)
    puts response.body
  end
end

if __FILE__ == $PROGRAM_NAME
  case ARGV[0]
  when 'add'
    if ARGV[1..].empty?
      puts "Error: No files provided for 'add' command."
    else
      FileStoreClient.add(*ARGV[1..]) # Pass all remaining arguments as file paths
    end
  when 'list'
    FileStoreClient.list
  when 'delete'
    FileStoreClient.delete(ARGV[1])
  when 'update'
    FileStoreClient.update(ARGV[1])
  when 'word_count'
    FileStoreClient.word_count
  when 'freq_words'
    limit = ARGV[1]&.to_i || 10
    order = ARGV[2] || 'desc'
    FileStoreClient.freq_words(limit, order)
  else
    puts 'Usage: ruby file_store_client.rb [command] [arguments]'
    puts 'Commands:'
    puts '  add <file_path>'
    puts '  list'
    puts '  delete <file_id>'
    puts '  update <file_path> <file_name>'
    puts '  word_count'
    puts '  freq_words [limit] [order]'
  end
end
