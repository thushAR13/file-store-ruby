class StoredFilesController < ApplicationController
  require 'digest'

  # List all files
  def index
    files = StoredFile.all
    render json: files
  end

  # Add a new file
  def create
    file_hash = params[:file_hash]
    new_name = params[:name]
  
    if file_hash.present?
      # Handle cases where the file hash is sent instead of a file
      existing_file = StoredFile.find_by(file_hash: file_hash)
      if existing_file
        begin
          # Create a new entry with the existing file's content
          new_file = StoredFile.create!(name: new_name, file_hash: file_hash)
          new_file.file.attach(existing_file.file.blob)
          render json: { message: 'File already exists. New entry created with existing content.', file: new_file }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      else
        render json: { error: 'File hash not found on the server.' }, status: :unprocessable_entity
      end
    else
      # Handle the case where a file is uploaded
      uploaded_file = params[:file]
      hash = Digest::SHA256.file(uploaded_file.tempfile).hexdigest
  
      begin
        stored_file = StoredFile.create!(name: uploaded_file.original_filename, file_hash: hash)
        stored_file.file.attach(uploaded_file)
        render json: stored_file, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
  
  

  # Delete a file
  def destroy
    stored_file = StoredFile.find_by(name: params[:name])
    if stored_file
      stored_file.file.purge
      stored_file.destroy
      render json: { message: 'File deleted successfully' }
    else
      render json: { error: 'File not found' }
    end
  end

  # Update a file
  def update
    stored_file = StoredFile.find_by(name: params[:file].original_filename)
    file = params[:file]
    if stored_file
      hash = Digest::SHA256.file(file.tempfile).hexdigest
      if stored_file.file_hash == hash
        render json: { message: 'No update needed' }
      else
        stored_file.file.attach(file)
        stored_file.update!(file_hash: hash)
        render json: stored_file
      end
    else
      create
    end
  end

  # Word count across all files
  def word_count
    total_words = StoredFile.all.sum do |stored_file|
      stored_file.file.download.split.size
    end
    render json: { total_words: total_words }
  end

  # Frequent words across all files
  def freq_words
    limit = params[:limit]&.to_i || 10
    order = params[:order] == 'asc' ? :asc : :desc

    word_counts = Hash.new(0)

    StoredFile.all.each do |stored_file|
      words = stored_file.file.download.split
      words.each { |word| word_counts[word] += 1 }
    end

    sorted_words = word_counts.sort_by { |_, count| count }
    sorted_words.reverse! if order == :desc
    render json: sorted_words.first(limit).to_h
  end

  def check_hash
    stored_file = StoredFile.find_by(file_hash: params[:file_hash])
    if stored_file
      render json: { match: true }
    else
      render json: { match: false }
    end
  end
end
