class StoredFilesController < ApplicationController
  require 'digest'

  # List all files
  def index
    files = StoredFile.all
    render json: files
  end

  # Add a new file
  def create
    file = params[:file]
    hash = Digest::SHA256.file(file.tempfile).hexdigest

    if StoredFile.exists?(file_hash: hash)
      render json: { error: 'File already exists' }, status: :conflict
    else
      stored_file = StoredFile.create!(name: file.original_filename, file_hash: hash)
      stored_file.file.attach(file)
      render json: stored_file, status: :created
    end
  end

  # Delete a file
  def destroy
    stored_file = StoredFile.find_by!(name: params[:name])
    stored_file.file.purge
    stored_file.destroy
    render json: { message: 'File deleted successfully' }
  end

  # Update a file
  def update
    stored_file = StoredFile.find_by(name: params[:name])
    file = params[:file]
    if stored_file
      hash = Digest::SHA256.file(file.tempfile).hexdigest
      if stored_file.file_hash == hash
        render json: { message: 'No update needed' }
      elsif duplicate = StoredFile.find_by(file_hash: hash)
        render json: { message: "File already exists under name #{duplicate.name}" }
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
end
